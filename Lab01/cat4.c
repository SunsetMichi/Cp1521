// Copy input to output
// CP1521

#include <stdlib.h>
#include <stdio.h>
#define MAX 100

void copy(FILE *, FILE *);

int main(int argc, char *argv[])
{
    FILE *fp;
	if(argc < 2){
        copy(stdin,stdout);
	} else {
	    if(( fp = fopen(argv[1], "r")) == NULL ) {
	        fprintf(stderr,"Can't read NameOfFile");
	    } else {
	        copy(fp,stdout);
	        fclose(fp);
	    }
	}
	return EXIT_SUCCESS;
}

// Copy contents of input to output
// Assumes both files open in appropriate mode

void copy(FILE *input, FILE *output)
{
    char character[MAX];
    while( fgets(character ,MAX, input) != NULL ){
        fputs(character, output);
    }
}
