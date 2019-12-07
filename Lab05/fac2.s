# CP1521 
# Compute factorials, iterative function


### Global data

   .data
msg1:
   .asciiz "n  = "
msg2:
   .asciiz "n! = "
eol:
   .asciiz "\n"

### main() function
   .text
   .globl main
main:
   #  set up stack frame
   sw    $fp, -4($sp)       # push $fp onto stack
   la    $fp, -4($sp)       # set up $fp for this function
   sw    $ra, -4($fp)       # save return address
   sw    $s0, -8($fp)       # save $s0 to use as ... int n;
   addi  $sp, $sp, -12      # reset $sp to last pushed item

   #  code for main()
   li    $s0, 0             # n = 0;
   
   la    $a0, msg1
   li    $v0, 4
   syscall                  # printf("n  = ");

   li    $v0, 5
   syscall                  # scanf("%d", into $v0)
   
# ... TODO: add your code here for  $s0 = fac(n); ...
# ... place the parameter in $a0 and get the result from $v0 ...

   move  $a0, $v0           # put n in $a0
   jal   fac                # call function fac
   move  $s0, $v0           # $s0 = fac(n)
   
   la    $a0, msg2
   li    $v0, 4
   syscall                  # printf("n! = ");

   move  $a0, $s0           # assume $s0 holds n!
   li    $v0, 1
   syscall                  # printf("%d\n",tmp);

   la    $a0, eol
   li    $v0, 4
   syscall                  # printf("\n");

   # clean up stack frame
   lw    $s0, -8($fp)       # restore $s0 value
   lw    $ra, -4($fp)       # restore $ra for return
   la    $sp, 4($fp)        # restore $sp (remove stack frame)
   lw    $fp, ($fp)         # restore $fp (remove stack frame)

   li    $v0, 0
   jr    $ra                # return 0

# fac() function

fac:
   # setup stack frame
   sw    $fp, -4($sp)       # push $fp onto stack
   la    $fp, -4($sp)       # set up $fp for this function
   sw    $ra, -4($fp)       # save return address
   sw    $s0, -8($fp)       # save $s0 to use as ... int i;
   sw    $s1, -12($fp)      # save $s1 to use as ... int prod;
   addi  $sp, $sp, -16      # reset $sp to last pushed item

   # code for fac()

# ... TODO: place your code for the body of fac() here ...
# ... use the value of n in $a0, place n! in $v0 ...

   li    $s0, 1             # i = 1 
   li    $s1, 1             # prod = 1;
   
top_while:

   bgt   $s0, $a0, end      # if(i > n)
   mul   $s1, $s1, $s0      # prod = prod * i;
   addi  $s0, $s0, 1        # i++;
   j     top_while                
   
end:

   move  $v0, $s1           # store prod in $v0 to return 

   # clean up stack frame
   lw    $s1, -12($fp)      # restore $s1 value
   lw    $s0, -8($fp)       # restore $s0 value
   lw    $ra, -4($fp)       # restore $ra for return
   la    $sp, 4($fp)        # restore $sp (remove stack frame)
   lw    $fp, ($fp)         # restore $fp (remove stack frame)

   jr    $ra                # return prod;
