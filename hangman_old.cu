#include <iostream>
#include <cstdlib>
#include <ctime>
#include <string>
#include <cuda_runtime.h>
#include <chrono>

using namespace std;
 using namespace chrono;


const int MAX_TRIES = 5;
#define WORD_SIZE 1048576

void init_zero(int* a, int n) {
 for (int i = 0; i < n; i++)
	a[i] = 0;
}

void init_null(char* a, int n) {
 for (int i = 0; i < n; i++)
	a[i] = '\0';
}

int letterFill(char, string, string&);

 void reportTime(const char* msg, steady_clock::duration span) { 

    double nsecs = double(span.count()) *
    steady_clock::period::num / steady_clock::period::den;
    std::cout << std::fixed;
    std::cout << msg << " - took - " <<
    nsecs << " secs" << std::endl;

 }
 
 
//gets matches, and edits strings..
__global__ void searchLetter(char* empty, char* word, char* guess, int* count, int* fcount, int n) {
	int i = blockIdx.x * blockDim.x + threadIdx.x;

	//if guessed letter is the letter at word[i]
	if (guess[0] == word[i]){
		//Add to count
		count[i] = 1;
		//Edit empty to have letter filled in.
		empty[i] = word[i];
	}
	else{
		count[i] = 0;
	}
	__syncthreads();
	
	for (int stride = 1; stride < n; stride *= 2) {
		if (i % (2 * stride) == 0)
			count[i] += count[i + stride];
		__syncthreads();
	}
	if (threadIdx.x == 0)
         fcount[blockIdx.x] = count[i];
}

__global__ void count_final(int* fcount, int n) {

	int i = threadIdx.x;

	for (int stride = 1; i + stride < n; stride *= 2) {
         if (i % (2 * stride) == 0)
             fcount[i] += fcount[i + stride];
         __syncthreads();
    }
	
}

int main()
{
	string name;
	char letter;
	int num_of_wrong_guesses = 0;
	string word;

	//choose and copy a word from array of words randomly
	srand(time(NULL));
	int n = rand() % 10;

	//test data to make load slow.
	word = "";
	int l;
	int fail1 = rand() % 26;
	int fail2 = rand() % 26;
	int fail3 = rand() % 26;
	int fail4 = rand() % 26;
	int super = rand() % 26;

	for (l = 0; l<WORD_SIZE; l++){

		int ran = rand() % 26;

		if (ran == fail1 || ran == fail2 || ran == fail3 || ran == fail4){

		}
		else if (ran == super){
			char cch = 'a' + ran;
			word += cch;
			word += cch;
			word += cch;
		}
		else{
			char cch = 'a' + ran;
			word += cch;
		}
	}

	int d;
	cudaDeviceProp prop;
	cudaGetDevice(&d);
	cudaGetDeviceProperties(&prop, d);
	int ntpb_x = prop.maxThreadsDim[0];
	cout << prop.major << prop.minor << endl;
	int nblks =  (WORD_SIZE + ntpb_x - 1) / ntpb_x; // number of blocks

		
	// Initialize the secret word with the * character.
	string unknown(word.length(), '*');
	// welcome the user
	cout << "\n\nWelcome to Letter Search...Guess a Letter!";
	cout << "\n\nEach letter is represented by a star.";
	cout << "\n\nYou have to type only one letter in one try";
	cout << "\n\nYou have " << MAX_TRIES << " tries to try and guess the word.";
	cout << "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
	// Loop until the guesses are used up
	while (num_of_wrong_guesses < MAX_TRIES)
	{
		
		
		//Uncomment below for better game play.
		//cout << "\n\n" << unknown;
		cout << "\n\nGuess a letter: ";
		cin >> letter;
		// Fill secret word with letter if the guess is correct,
		// otherwise increment the number of wrong guesses.

		//TODO
		    steady_clock::time_point ts, te;
		std::srand(std::time(nullptr));
		ts = steady_clock::now();


		int n = word.length();

		//MEMaloc d_empty, d_word, d_guess, d_count

		char* d_empty;
		cudaMalloc((void**)&d_empty, nblks * ntpb_x*sizeof(char));

		char*d_word;
		cudaMalloc((void**)&d_word, nblks * ntpb_x*sizeof(char));

		char* d_guess;
		cudaMalloc((void**)&d_guess, sizeof(char));

		int* d_count;
		cudaMalloc((void**)&d_count, nblks * ntpb_x*sizeof(int));

		int* d_fcount;
		cudaMalloc((void**)&d_fcount, nblks*sizeof(int));
		
		char* wordchar = new char[nblks * ntpb_x];
		init_null( wordchar, nblks * ntpb_x);
		char* emptychar = new char[nblks * ntpb_x];
		init_null( emptychar, nblks * ntpb_x);
		char* guesschar = new char[sizeof(char)];
		int * h_count = new int[nblks * ntpb_x];
		init_zero(h_count, nblks * ntpb_x);
		int * h_fcount = new int[nblks];


		//int lets = 0; not needed
		//this should go to kernal.
		//lets = letterFill(letter, word, unknown);
		//End going to kernel.

		//TODO
		

		//MEMCPY all above to device

		//first put stings into char array

		memcpy(wordchar, word.c_str(), word.length() + 1);
		memcpy(emptychar, unknown.c_str(), unknown.length() + 1);
		guesschar = &letter;

		//Copy char arrays into cuda.
		cudaMemcpy(d_empty, emptychar, nblks * ntpb_x * sizeof(char), cudaMemcpyHostToDevice);
		cudaMemcpy(d_word, wordchar, nblks * ntpb_x * sizeof(char), cudaMemcpyHostToDevice);
		cudaMemcpy(d_guess, guesschar, sizeof(char), cudaMemcpyHostToDevice);
		cudaMemcpy(d_count, h_count, nblks * ntpb_x * sizeof(int), cudaMemcpyHostToDevice);
		cudaMemcpy(d_fcount, h_count, nblks * sizeof(int), cudaMemcpyHostToDevice);



		searchLetter <<<nblks, ntpb_x>>>(d_empty, d_word, d_guess, d_count, d_fcount, ntpb_x);
		count_final <<<1, nblks>>>(d_fcount, nblks);

		//reverse above steps.

		cudaMemcpy(emptychar, d_empty, n * sizeof(char), cudaMemcpyDeviceToHost);
		cudaMemcpy(wordchar, d_word, n * sizeof(char), cudaMemcpyDeviceToHost);
		cudaMemcpy(guesschar, d_guess, sizeof(char), cudaMemcpyDeviceToHost);
		cudaMemcpy(h_count, d_fcount, nblks*sizeof(int), cudaMemcpyDeviceToHost);

		//copied back to chars, now copy to strings
		unknown = emptychar;

		te = steady_clock::now();
		reportTime("Search Time: ", te - ts); 
		
		int final_count = h_count[0];
		if (final_count == 0)
		{
			cout << endl << "Whoops! That letter isn't in there!" << endl;
			num_of_wrong_guesses++;
		}
		else
		{
			cout << endl << "You found " << final_count << " letters! Isn't that exciting!" << endl;
		}
		// Tell user how many guesses has left.
		cout << "You have " << MAX_TRIES - num_of_wrong_guesses;
		cout << " guesses left." << endl;
		// Check if user guessed the word.
		if (word == unknown)
		{
			cout << word << endl;
			cout << "Yeah! You got it!";
			break;
		}
	
	// TODO
	// cuda free var's
	 cudaFree(d_empty);
	 cudaFree(d_word);
	 cudaFree(d_guess);
	 cudaFree(d_count);
	}



	if (num_of_wrong_guesses == MAX_TRIES)
	{
		cout << "\nSorry, you lose...you've been hanged." << endl;
		cout << "The word was : " << word << endl;
	}
	cin.ignore();
	cin.get();
	return 0;
}
/* Take a one character guess and the secret word, and fill in the
unfinished guessword. Returns number of characters matched.
Also, returns zero if the character is already guessed. */
int letterFill(char guess, string secretword, string &guessword)
{
	int i;
	int matches = 0;
	int len = secretword.length();
	for (i = 0; i< len; i++)
	{
		// Did we already match this letter in a previous guess?
		if (guess == guessword[i])
			return 0;
		// Is the guess in the secret word?
		if (guess == secretword[i])
		{
			guessword[i] = guess;
			matches++;
		}
	}
	return matches;
}

