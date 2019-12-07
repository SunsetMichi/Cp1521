# asterisks.s
#
#int main(void){
#    int i, n;
#    printf("Enter the number of asterisks: ");   
#    scanf("%d",&n);
#    i = 0;
#    while(i < n){
#        printf("*\n");
#        i++;
#    }
#    return 0;
#}

### Global data

   .data

input_msg:
   .asciiz "Enter the number of asterisks: "
eol:
   .asciiz "\n"
asterisk:
   .asciiz "*"


### main() function
   .text
   .globl main

main:
   la    $a0, input_msg
   li    $v0, 4
   syscall                  # printf("Enter the number of asterisks: ");

   li    $v0, 5
   syscall                  # scanf("%d", into $v0)
   move $s0, $v0            # store n in $s0

# ... TODO: your code for the body of main() goes here ..
   li    $t0, 0             # i = 0

top_while:
   bge   $t0, $s0, exit     # if(i >= n)
   
   la    $a0, asterisk      # printf("*");
   li    $v0, 4
   syscall
   
   la    $a0, eol           # printf("\n");
   li    $v0, 4
   syscall
   
   addi  $t0, $t0, 1        # i++;
   j  top_while

exit:

   li    $v0, 0
   jr    $ra                # return 0
