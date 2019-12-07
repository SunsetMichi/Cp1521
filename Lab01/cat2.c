// Copy input to output
// CP1521

#include <stdlib.h>
#include <stdio.h>

void copy(FILE *, FILE *);

int main(int argc, char *argv[])
{
	copy(stdin,stdout);
	return EXIT_SUCCESS;
}

// Copy contents of input to output, char-by-char
// Assumes both files open in appropriate mode

void copy(FILE *input, FILE *output)
{
    char character;
    while( (character = fgetc(input)) != EOF ){
        fputc(character, output);
    }
}
