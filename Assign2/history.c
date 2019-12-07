// CP1521 mysh ... command history
// Implements an abstract data object

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "history.h"

// This is defined in string.h
// BUT ONLY if you use -std=gnu99
//extern char *strdup(const char *s);

// Command History
// array of command lines
// each is associated with a sequence number

#define MAXHIST 20
#define MAXSTR  200

#define HISTFILE ".mymysh_history"

typedef struct _history_entry {
   int   seqNumber;
   char *commandLine;
} HistoryEntry;

typedef struct _history_list {
   int nEntries;
   HistoryEntry commands[MAXHIST];
} HistoryList;

HistoryList CommandHistory;

// initCommandHistory()
// - initialise the data structure
// - read from .history if it exists

int initCommandHistory()
{
    // TODO
    CommandHistory.nEntries = 0;
    int i = 0;

    // Malloc space for the history command lines
    for (i = 0; i < MAXHIST; i++) {
        CommandHistory.commands[i].commandLine = malloc(sizeof(char)*(MAXSTR));   
        CommandHistory.commands[i].seqNumber = 0;
    }
    // Open the file that contains the most recent 20 histories
    FILE *history; 
    char string[MAXSTR];
    
    // getenv to get the environment variable and get the history stored
    strcpy(string, getenv("HOME"));
    strcat(string, "/"); 
    strcat(string, HISTFILE);

    history = fopen(string,"r");
    int commandNo;

    // If the history is empty then first cmd starts with 1
    if (history == NULL) {
        commandNo = 1;
    } else {
        i = 0;
        // scan the command line and seqNo of previous history
        while (fscanf(history, " %3d", &commandNo) != EOF) {
            if (i < MAXHIST) {
                CommandHistory.commands[i].seqNumber = commandNo;
                // get rid of the spaces in between
                getc(history);
                getc(history);
                
                // Scan the command line
                fgets(CommandHistory.commands[i].commandLine, MAXSTR, history);
                int j = 0;
                // Get rid of the newline of the fgets
                while(CommandHistory.commands[i].commandLine[j] != '\n') {
                    j++;
                }
                CommandHistory.commands[i].commandLine[j] = '\0';
            }
            i++;
        }
        // Set the number of entries
        CommandHistory.nEntries = i;
        // The cmdNo should be the last command plus one so that it does not reinitialize into 0
        commandNo = CommandHistory.commands[i - 1].seqNumber + 1;
        fclose(history);
    }
    return commandNo;
}

// addToCommandHistory()
// - add a command line to the history list
// - overwrite oldest entry if buffer is full

void addToCommandHistory(char *cmdLine, int seqNo)
{
    // TODO
    int position = CommandHistory.nEntries;

    // If history list is not full yet
    if (CommandHistory.nEntries < MAXHIST) {
        CommandHistory.commands[position].seqNumber = seqNo;
        CommandHistory.commands[position].commandLine = strdup(cmdLine);
        
        // Increment the entryNo for a new command
        position = position + 1;
        CommandHistory.nEntries = position;
    } else if (CommandHistory.nEntries == MAXHIST) {

            // Shift one history before in the list
            for (int i = 0; i < MAXHIST - 1; i++) {
                //free(CommandHistory.commands[i].commandLine);
                CommandHistory.commands[i].seqNumber = CommandHistory.commands[i+1].seqNumber;
                CommandHistory.commands[i].commandLine = strdup(CommandHistory.commands[i+1].commandLine);
            }
            // For the last one added
            CommandHistory.commands[MAXHIST - 1].seqNumber = seqNo; 
            CommandHistory.commands[MAXHIST - 1].commandLine = strdup(cmdLine); 
    }
    
}

// showCommandHistory()
// - display the list of 

void showCommandHistory(FILE *outf)
{
    // TODO
    // Loop to print the history based on No of entries
    for (int i = 0; i < CommandHistory.nEntries; i++) {
        printf(" %3d  %s\n", CommandHistory.commands[i].seqNumber, CommandHistory.commands[i].commandLine);
    } 
}

// getCommandFromHistory()
// - get the command line for specified command
// - returns NULL if no command with this number

char *getCommandFromHistory(int cmdNo)
{
    // TODO
    // Loop to search for a command with its cmdNo
    for (int i = 0; i < MAXHIST; i++) {
        if(CommandHistory.commands[i].seqNumber == cmdNo) {
            return CommandHistory.commands[i].commandLine;
        }
    }
    return NULL;
}

// saveCommandHistory()
// - write history to $HOME/.mymysh_history

void saveCommandHistory()
{
    // TODO
    FILE *history;
    char historyPath[MAXSTR];
    // Save history list in the home directory
    strcpy(historyPath,getenv("HOME"));
    strcat(historyPath,"/.mymysh_history");
    history = fopen(historyPath, "w");
    
    // Loop to write the list into the history file
    for (int i = 0; i < CommandHistory.nEntries; i++) {
        fprintf(history, " %3d  %s\n", CommandHistory.commands[i].seqNumber, CommandHistory.commands[i].commandLine);
    }
    fclose(history);
}

// cleanCommandHistory
// - release all data allocated to command history

void cleanCommandHistory()
{
    // TODO
    // Loop to free all malloc spaces
    for (int i = 0; i < CommandHistory.nEntries; i++) {
        free(CommandHistory.commands[i].commandLine);
    }
}
