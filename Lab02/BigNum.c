// BigNum.h ... LARGE positive integer values

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <ctype.h>
#include "BigNum.h"

// Initialise a BigNum to N bytes, all zero
void initBigNum(BigNum *n, int Nbytes)
{
   // TODO
   n->bytes = malloc((Nbytes+1)*(sizeof(Byte)));
   assert(n->bytes != NULL);
   n->nbytes = Nbytes;
   memset(n->bytes,'0',Nbytes);
}

// Add two BigNums and store result in a third BigNum
void addBigNums(BigNum n, BigNum m, BigNum *res)
{
   // TODO
   int i = 0;
   int carry = 0;
   int sum = 0;
   int flag = 0;
   int maxSize = n.nbytes;
   if(n.nbytes>m.nbytes){
        maxSize = n.nbytes;
        flag = 1;
   } else {
        maxSize = m.nbytes;
   }
   while( i < maxSize ){
        
        int num1 = n.bytes[i]-'0';
        int num2 = m.bytes[i]-'0';
        if( i >= m.nbytes && flag == 1 ){
            num2 = 0;
        }
        if( i >= n.nbytes && flag != 1 ){
            num1 = 0;
        }
        
        sum = num1 + num2 + carry;
        carry = sum/10;

        // if i is equal to nbytes-1 AND (there is a carry OR you haven't finished going through the inputs)
        // "is on the last charcter in the input" = that i < largerSize - 1
        if(i == res->nbytes ){
            res->bytes = realloc(res->bytes,sizeof(Byte)*maxSize);
            res->nbytes = maxSize;
            for(int j=i;j<maxSize;j++){
                res->bytes[j]='0';
            }
        }
        
        res->bytes[i] = (sum%10)+'0';
        i++;
   }
}

// Set the value of a BigNum from a string of digits
// Returns 1 if it *was* a string of digits, 0 otherwise
int scanBigNum(char *s, BigNum *n)
{
   // TODO
   int j = 0;
   int k = 0;
   for(int i = strlen(s)-1; i >= 0; i--){
        if(s[i] >= '0' && s[i] <= '9'){
            if(j == n->nbytes - 1 ){
                n->bytes = realloc(n->bytes,n->nbytes*2*sizeof(Byte));
                n->nbytes=n->nbytes*2;
            }
            n->bytes[j] = s[i];
            j++;
        } else {
            k++;
        }
        if(k==strlen(s)){
            return 0;
        }
        memset(&(n->bytes[j]),'0',n->nbytes-j);
   }
   return 1;
}

// Display a BigNum in decimal format
void showBigNum(BigNum n)
{
   // TODO
   int i = n.nbytes-1;

   while(i >= 0) {
        if(n.bytes[i] != '0'){
            break;
        }
        i--;
   }
   while(i >= 0){
        putchar(n.bytes[i]);
        i--;
   }
}

void freeBigNum(BigNum n){
   // TODO
   free(n.bytes);
}
