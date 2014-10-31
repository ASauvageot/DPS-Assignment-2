#include <iostream>
#include <cstdlib>
#include <ctime>
#include <string>
#include <cuda_runtime.h>
using namespace std;
const int MAX_TRIES = 5;
int letterFill(char, string, string&);

//gets matches, and edits strings..
__global__ void searchLetter(char* empty, char* word, char* guess, int* count, int n) {
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
	for (int stride = 1; i + stride < n; stride *= 2) {
		if (i % (2 * stride) == 0)
			count[i] += count[i + stride];
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

	for (l = 0; l<1020; l++){

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

	//End Getting Test Data

	// Initialize the secret word with the * character.
	string unknown(word.length(), '*');
	// welcome the user
	cout << "\n\nWelcome to hangman...Guess a country Name";
	cout << "\n\nEach letter is represented by a star.";
	cout << "\n\nYou have to type only one letter in one try";
	cout << "\n\nYou have " << MAX_TRIES << " tries to try and guess the word.";
	cout << "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
	// Loop until the guesses are used up
	while (num_of_wrong_guesses < MAX_TRIES)
	{
		//Uncomment below for better game play.
		cout << "\n\n" << unknown;
		cout << "\n\nGuess a letter: ";
		cin >> letter;
		// Fill secret word with letter if the guess is correct,
		// otherwise increment the number of wrong guesses.

		//TODO
		int n = word.length();

		//MEMaloc d_empty, d_word, d_guess, d_count

		char* d_empty;
		cudaMalloc((void**)&d_empty, n*sizeof(char));

		char*d_word;
		cudaMalloc((void**)&d_word, n*sizeof(char));

		char* d_guess;
		cudaMalloc((void**)&d_guess, sizeof(char));

		int* d_count;
		cudaMalloc((void**)&d_count, sizeof(int));

		char* wordchar = new char[word.length() + 1];
		char* emptychar = new char[word.length() + 1];
		char* guesschar = new char[sizeof(char)];
		int * h_count = new int[word.length()];


		//int lets = 0; not needed
		//this should go to kernal.
		//lets = letterFill(letter, word, unknown);
		//End going to kernal.

		//TODO


		//MEMCPY all above to device

		//first put stings into char array

		memcpy(wordchar, word.c_str(), word.length() + 1);
		memcpy(emptychar, unknown.c_str(), unknown.length() + 1);
		guesschar = &letter;

		//Copy char arrays into cuda.
		cudaMemcpy(d_empty, emptychar, n * sizeof(char), cudaMemcpyHostToDevice);
		cudaMemcpy(d_word, wordchar, n * sizeof(char), cudaMemcpyHostToDevice);
		cudaMemcpy(d_guess, guesschar, sizeof(char), cudaMemcpyHostToDevice);
		cudaMemcpy(d_count, h_count, n * sizeof(int), cudaMemcpyHostToDevice);

		searchLetter << <10, word.length() / 10 >> >(d_empty, d_word, d_guess, d_count, n);

		//reverse above steps.

		cudaMemcpy(emptychar, d_empty, n * sizeof(char), cudaMemcpyDeviceToHost);
		cudaMemcpy(wordchar, d_word, n * sizeof(char), cudaMemcpyDeviceToHost);
		cudaMemcpy(guesschar, d_guess, sizeof(char), cudaMemcpyDeviceToHost);
		cudaMemcpy(h_count, d_count, sizeof(int), cudaMemcpyDeviceToHost);

		//copied back to chars, now copy to strings
		unknown = emptychar;


		if (h_count[0] == 0)
		{
			cout << endl << "Whoops! That letter isn't in there!" << endl;
			num_of_wrong_guesses++;
		}
		else
		{
			cout << endl << "You found " << h_count[0] << " letters! Isn't that exciting!" << endl;
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
	}

	// TODO
	// delete all char[]'s
	// delete [] emptychar;
	// delete [] wordchar;
	// delete [] guesschar;

	// cuda free var's
	// cudaFree(d_empty);
	// cudaFree(d_word);
	// cudaFree(d_guess);
	// cudaFree(d_count);


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


