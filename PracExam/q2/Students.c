// Students.c ... implementation of Students datatype

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <assert.h>
#include "Students.h"

typedef struct _stu_rec {
	int   id;
	char  name[20];
	int   degree;
	float wam;
} sturec_t;

typedef struct _students {
    int    nstu;
    StuRec recs;
} students_t;

// build a collection of student records from a file descriptor
Students getStudents(int in)
{
	//return NULL;  // TODO ... replace this by your code
	struct stat info;
	// get information about the file
	fstat(in, &info);
	off_t size = info.st_size;
	
	int nStudents = size / sizeof(sturec_t);
	sturec_t *students = malloc(nStudents*sizeof(sturec_t));
	read(in, &students, size);
    students_t *new =  malloc(sizeof(students_t));
    new->nstu = nStudents;
    new->recs = students;
    
    return new;
}   

// show a list of student records pointed to by ss
void showStudents(Students ss)
{
	assert(ss != NULL);
	for (int i = 0; i < ss->nstu; i++)
		showStuRec(&(ss->recs[i]));
}

// show one student record pointed to by s
void showStuRec(StuRec s)
{
	printf("%7d %s %4d %0.1f\n", s->id, s->name, s->degree, s->wam);
}
