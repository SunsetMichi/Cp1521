// where_are_the_bits.c ... determine bit-field order
// CP1521 Lab 03 Exercise
// Written by Megan Wong z5241209 on 10/09/2019

#include <stdio.h>
#include <stdlib.h>

struct _bit_fields {
   unsigned int a : 4,
                b : 8,
                c : 20;
};

int main(void)
{
   struct _bit_fields x = {-1, 0, -1};
   unsigned int *p = (unsigned int *) &x;
   printf("%x\n",*p);
   /*unsigned int *ptrX = (unsigned int *) &x;
   unsigned int mask = 1;
   
   int i = 0;

   while( i < 32) {
        if((*ptrX & mask) > 0) {
            printf("1");
        } else {
            printf("0");
        }
        
        i++;
        mask = mask << 1;
   }
    printf("\n");*/

   return 0;
}
