// mysh.c ... a small shell
// Started by John Shepherd, September 2018
// Completed by <<Megan Michelle Wong>>, <<November 2019>>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <glob.h>
#include <assert.h>
#include <fcntl.h>
#include "history.h"

// This is defined in string.h
// BUT ONLY if you use -std=gnu99
//extern char *strdup(char *);

// Function forward references

void trim(char *);
int strContains(char *, char *);
char **tokenise(char *, char *);
char **fileNameExpand(char **);
void freeTokens(char **);
char *findExecutable(char *, char **);
int isExecutable(char *);
void prompt(void);
void execute(char **args, char **path, char **envp);
void getCurrentDirectory();


// Global Constants

#define MAXLINE 200

// Global Data

/* none ... unless you want some */


// Main program
// Set up enviroment and then run main loop
// - read command, execute command, repeat

int main(int argc, char *argv[], char *envp[])
{
   pid_t pid;   // pid of child process
   int stat;    // return status of child
   char **path; // array of directory names
   int cmdNo;   // command number
   int i;       // generic index

   // set up command PATH from environment variable
   for (i = 0; envp[i] != NULL; i++) {
      if (strncmp(envp[i], "PATH=", 5) == 0) break;
   }
   if (envp[i] == NULL)
      path = tokenise("/bin:/usr/bin",":");
   else
      // &envp[i][5] skips over "PATH=" prefix
      path = tokenise(&envp[i][5],":");
#ifdef DBUG
   for (i = 0; path[i] != NULL;i++)
      printf("path[%d] = %s\n",i,path[i]);
#endif

   // initialise command history
   // - use content of ~/.mymysh_history file if it exists

   cmdNo = initCommandHistory();

   // main loop: print prompt, read line, execute command

   char line[MAXLINE];
   prompt();
   while (fgets(line, MAXLINE, stdin) != NULL) {
      trim(line); // remove leading/trailing space

      // TODO
      // Code to implement mainloop goes here
      
      // For each command line, print before executing
      printf("%s\n", line);
      
      // If empty command ignore
      if (strcmp(line,"") == 0) { 
         prompt(); 
         continue; 
      }
      // Uses
      // - addToCommandHistory()
      // - showCommandHistory()
      // - and many other functions
      // TODO

      // Handle ! history substitution
      int historyNo = 0;
      if (line[0] == '!') {
        // !! command goes to previous history
        if( line[1] == '!') {
            strcpy(line, getCommandFromHistory(cmdNo - 1));
        } else {
            char *sequenceNo = &line[1];
            historyNo = atoi(sequenceNo);
            if (historyNo == 0) {
                printf("No command #0\n");
                prompt();
                continue;
            } else {
                int range = cmdNo - 20;
                // If the number requested is out of range of the list, print error message
                // otherwise execute the command 
                if (historyNo >= range && historyNo < cmdNo) {
                    strcpy(line, getCommandFromHistory(historyNo));
                    printf("%s\n", line);
                } else if (historyNo < range || historyNo > cmdNo) {
                    printf("No command #%d\n",historyNo);
                    prompt();
                    continue;
                }
            }
        }
      }
      
      // Tokenise
      char **toks = tokenise(line, " ");
      
      // Handle '*', '?', '[', '~' filename expansion (Wildcards)
      // If there are any wildcard symbol in the command line, expand files
      if (strchr(line,'*') != NULL || strchr(line,'?') != NULL
        || strchr(line,'[') != NULL || strchr(line,'~') != NULL) {
            toks = fileNameExpand(toks);
      }
      
      // Handle shell built-ins
      // "exit" exits the program and saves the history
      if (strcmp(toks[0],"exit") == 0) {
            break;
      } 
      // "h" or "history" prints the command history list
      else if (strcmp(toks[0], "h") == 0 || strcmp(toks[0], "history") == 0) {
            showCommandHistory(stdout);
            addToCommandHistory(line,cmdNo);
            cmdNo++;
            prompt();
            continue;
      } 
      // "pwd" gets the current working directory
      else if (strcmp(toks[0],"pwd") == 0) {
            getCurrentDirectory();
            addToCommandHistory(line,cmdNo);
            cmdNo++;
            prompt();
            continue;
      } 
      // cd changes the current working directory
      else if (strcmp(toks[0], "cd") == 0) {
            // If only cd goes to home directory
            if (strcmp(line, "cd") == 0) {
                //getenv to get environment variable HOME
                chdir(getenv("HOME"));  
                getCurrentDirectory();

            // cd .. to go to previous directory
            } else if (strcmp(toks[1], "..") == 0) {
                chdir("..");
                getCurrentDirectory();
            } else {
                // Change to dir given as command line argument
                int change = chdir(toks[1]);
                
                // If chdir returns -1, print error message
                // otherwise change directory
                if (change == -1) {
                    printf("%s: No such file or directory\n", argv[1]);
                    prompt();
                    continue;
                } else {
                    getCurrentDirectory();
                }
            }
            addToCommandHistory(line, cmdNo);
            cmdNo++;
            prompt();
            continue;
      }

      
      // Input output redirections error check
      char *redirect = NULL;
      int inputFlag = 0;
      int outputFlag = 0;
      int errorFlag = 0;

      for(int i = 0; toks[i] != NULL; i++) {
         if (strcmp(toks[i], ">") == 0) {
            // If file to redirect does not exits or there is more than one redirection is an error
            if (toks[i + 1] == NULL || toks[i + 2] != NULL) {
               printf("Invalid i/o redirection\n");
               errorFlag = 1;
               break;
            }
            outputFlag = 1;
            // Set redirect to be the filename of redirection
            redirect = toks[i + 1];
            toks[i] = NULL;
            break;
         } else if (strcmp(toks[i], "<") == 0) {
            if (toks[i + 1] == NULL || toks[i + 2] != NULL) {
               printf("Invalid i/o redirection\n");
               errorFlag = 1;
               break;
            }
            inputFlag = 1;
            redirect = toks[i + 1];
            toks[i] = NULL;
            break;
         }
      }
      // If it was and invalid redirection print prompt
      if (errorFlag == 1) {
         prompt();
         continue;
      }
      // If the input file does not exits i/o redirection fails
      if (inputFlag == 1) {
         int fd = open(redirect, O_RDONLY);
         if (fd == -1) {
            printf("Input redirection: No such file or directory\n");
            prompt();
            continue;
         }
         close(fd);
      }

      // Normal commands
      // Create a child process
      pid = fork();
      if (pid < 0) {
            printf("Child process could not be created");
            exit(EXIT_FAILURE);  
      // Parent process        
      } else if (pid != 0) {
            if (findExecutable(toks[0], path) != NULL) {
               char *command = NULL;
               char pathTemp[BUFSIZ];
               if (toks[0][0] == '/' || toks[0][0] == '.') {
                  if (isExecutable(toks[0]) == 1) {
                     command = toks[0];
                  }
               } else {
                  for (int i = 0; path[i] != NULL; i++) {
                     strcpy(pathTemp, path[i]);
                     strcat(pathTemp,"/");
                     strcat(pathTemp, toks[0]);
                     if (isExecutable(pathTemp) == 1) {
                        command = pathTemp;
                        break;
                     }
                  }
               }
               printf("Running %s ...\n",command);
               printf("--------------------\n");
            } else {
               printf("%s: Command not found\n", toks[0]);
            }
            // Wait for the child to finish
            wait(&stat);
            printf("--------------------\n");
            // Set return status number
            printf("Returns %d\n", WEXITSTATUS(stat));
            addToCommandHistory(line, cmdNo);
            cmdNo++;
            free(toks);
      // Child process
      } else if (pid == 0) {
         if (inputFlag == 1) {
            // For input redirections just open in read mode
            int inputfd = open(redirect, O_RDONLY);
            if (inputfd == -1) {
               printf("Input redirection: No such file or directory\n");
               prompt();
               continue;
            }
            // newfd is the file descriptor for stdin
            dup2(inputfd, STDIN_FILENO);
            close(inputfd);
         } else if (outputFlag == 1) {
            // If is output redirection open in read, write and if the file doesn't exit create one
            int outputfd = open(redirect, O_WRONLY | O_CREAT, 0666);
            if (outputfd == -1) {
               printf("Input redirection: No such file or directory\n");
               prompt();
               continue;
            }
            // newfd is the file descriptor for stdout
            dup2(outputfd, STDOUT_FILENO);
            close(outputfd);
         }
         execute(toks, path, envp);
      }
      prompt();
   }
   // When exiting, save command history and free all memory allocated
   saveCommandHistory();
   cleanCommandHistory();
   printf("\n");
   return(EXIT_SUCCESS);
}

// Function to get the current working directory
void getCurrentDirectory() {
    char currDirectory[MAXLINE];
    if (getcwd(currDirectory, sizeof(currDirectory)) != NULL) {
        printf("%s\n", currDirectory);
    } else {
        perror("getcwd() error\n");
    }
}

// fileNameExpand: expand any wildcards in command-line args
// - returns a possibly larger set of tokens
char **fileNameExpand(char **tokens)
{
   // TODO
   int i = 0;
   char sconcat[MAXLINE];
   while(tokens[i] != NULL) {
        // If "*", "?", "[", "~" symbols are found in the token, expand
        if(strchr(tokens[i], '*') != NULL || strchr(tokens[i], '?') != NULL 
        || strchr(tokens[i], '[') != NULL || strchr(tokens[i], '~') != NULL) {
            // Get the array of tokens that matches
            glob_t gbuffer;
            glob(tokens[i], GLOB_NOCHECK | GLOB_TILDE, 0, &gbuffer);
            
            // Loops to concatenate each file name with " "
            for(int j = 0; j < gbuffer.gl_pathc; j++) {
               strcat(sconcat, gbuffer.gl_pathv[j]);
               strcat(sconcat, " ");
            }
            globfree(&gbuffer);
        } else {
            strcat(sconcat, tokens[i]);
            strcat(sconcat, " ");
        }
        i++;
   }
   // Tokenise the file names
   char **matches = tokenise(sconcat, " ");
   return matches;
}

// execute: run a program, given command-line args, path and envp
void execute(char **args, char **path, char **envp)
{  
   // Find executable
   char *command = NULL;
   char pathTemp[BUFSIZ];
   if(args[0][0] == '/' || args[0][0] == '.') {
        if(isExecutable(args[0]) == 1) {
            command = args[0];
        }
   } else {
        for(int i = 0; path[i] != NULL; i++) {
            strcpy(pathTemp, path[i]);
            strcat(pathTemp,"/");
            strcat(pathTemp, args[0]);
            if(isExecutable(pathTemp) == 1) {
                command = pathTemp;
                break;
            }
        }
   }
   // If execve fails, print error message
   if(command != NULL) {
        execve(command, args, envp);
        printf("%s: unknown type of executable\n", command);
        exit(255); 
   } 
}

// findExecutable: look for executable in PATH
char *findExecutable(char *cmd, char **path)
{
      char executable[MAXLINE];
      executable[0] = '\0';
      if (cmd[0] == '/' || cmd[0] == '.') {
         strcpy(executable, cmd);
         if (!isExecutable(executable))
            executable[0] = '\0';
      }
      else {
         int i;
         for (i = 0; path[i] != NULL; i++) {
            sprintf(executable, "%s/%s", path[i], cmd);
            if (isExecutable(executable)) break;
         }
         if (path[i] == NULL) executable[0] = '\0';
      }
      if (executable[0] == '\0')
         return NULL;
      else
         return strdup(executable);
}

// isExecutable: check whether this process can execute a file
int isExecutable(char *cmd)
{
   struct stat s;
   // must be accessible
   if (stat(cmd, &s) < 0)
      return 0;
   // must be a regular file
   //if (!(s.st_mode & S_IFREG))
   if (!S_ISREG(s.st_mode))
      return 0;
   // if it's owner executable by us, ok
   if (s.st_uid == getuid() && s.st_mode & S_IXUSR)
      return 1;
   // if it's group executable by us, ok
   if (s.st_gid == getgid() && s.st_mode & S_IXGRP)
      return 1;
   // if it's other executable by us, ok
   if (s.st_mode & S_IXOTH)
      return 1;
   return 0;
}

// tokenise: split a string around a set of separators
// create an array of separate strings
// final array element contains NULL
char **tokenise(char *str, char *sep)
{
   // temp copy of string, because strtok() mangles it
   char *tmp;
   // count tokens
   tmp = strdup(str);
   int n = 0;
   strtok(tmp, sep); n++;
   while (strtok(NULL, sep) != NULL) n++;
   free(tmp);
   // allocate array for argv strings
   char **strings = malloc((n+1)*sizeof(char *));
   assert(strings != NULL);
   // now tokenise and fill array
   tmp = strdup(str);
   char *next; int i = 0;
   next = strtok(tmp, sep);
   strings[i++] = strdup(next);
   while ((next = strtok(NULL,sep)) != NULL)
      strings[i++] = strdup(next);
   strings[i] = NULL;
   free(tmp);
   return strings;
}

// freeTokens: free memory associated with array of tokens
void freeTokens(char **toks)
{
   for (int i = 0; toks[i] != NULL; i++)
      free(toks[i]);
    free(toks);
}

// trim: remove leading/trailing spaces from a string
void trim(char *str)
{
   int first, last;
   first = 0;
   while (isspace(str[first])) first++;
   last  = strlen(str)-1;
   while (isspace(str[last])) last--;
   int i, j = 0;
   for (i = first; i <= last; i++) str[j++] = str[i];
   str[j] = '\0';
}

// strContains: does the first string contain any char from 2nd string?
int strContains(char *str, char *chars)
{
   for (char *s = str; *s != '\0'; s++) {
      for (char *c = chars; *c != '\0'; c++) {
         if (*s == *c) return 1;
      }
   }
   return 0;
}

// prompt: print a shell prompt
// done as a function to allow switching to $PS1
void prompt(void)
{
   printf("mymysh$ ");
}
