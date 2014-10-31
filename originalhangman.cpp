#include <iostream>
#include <cstdlib>
#include <ctime>
#include <string>
using namespace std;
const int MAX_TRIES=5;
#define WORD_SIZE 1000000
int letterFill (char, string, string&);
int main ()
{
string name;
char letter;
int num_of_wrong_guesses=0;
string word;
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
// Initialize the secret word with the * character.
string unknown(word.length(),'*');
// welcome the user
cout << "\n\nWelcome to hangman...Guess a country Name";
cout << "\n\nEach letter is represented by a star.";
cout << "\n\nYou have to type only one letter in one try";
cout << "\n\nYou have " << MAX_TRIES << " tries to try and guess the word.";
cout << "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
// Loop until the guesses are used up
while (num_of_wrong_guesses < MAX_TRIES)
{
//cout << "\n\n" << unknown;
cout << "\n\nGuess a letter: ";
cin >> letter;
// Fill secret word with letter if the guess is correct,
// otherwise increment the number of wrong guesses.
if (letterFill(letter, word, unknown)==0)


{
cout << endl << "Whoops! That letter isn't in there!" << endl;
num_of_wrong_guesses++;
}
else
{
cout << endl << "You found a letter! Isn't that exciting!" << endl;
}
// Tell user how many guesses has left.
cout << "You have " << MAX_TRIES - num_of_wrong_guesses;
cout << " guesses left." << endl;
// Check if user guessed the word.
if (word==unknown)
{
cout << word << endl;
cout << "Yeah! You got it!";
break;
}
}
if(num_of_wrong_guesses == MAX_TRIES)
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
int letterFill (char guess, string secretword, string &guessword)
{
int i;
int matches=0;
int len=secretword.length();
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

/*
			Call graph


granularity: each sample hit covers 2 byte(s) no time propagated

index % time    self  children    called     name
                0.00    0.00       1/1           __libc_csu_init [15]
[8]      0.0    0.00    0.00       1         _GLOBAL__sub_I_main [8]
-----------------------------------------------

Index by function name

   [8] _GLOBAL__sub_I_main (hangman2.cpp)
*/

