# CP1521 Lab
# Compute factorials, recursive function


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
   syscall
   move  $s0, $v0           # scanf("%d", &n);
   
   move  $a0, $s0           
   jal   fac
   move  $s0, $v0           # tmp = fac(n);
                            # recycle $s0, don't need n now
   la    $a0, msg2
   li    $v0, 4
   syscall                  # printf("n! = ");

   move  $a0, $s0
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
   # set up stack frame
# ... TODO ...
   sw    $fp, -4($sp)       # push $fp onto stack
   la    $fp, -4($sp)       # set up $fp for this function
   sw    $ra, -4($fp)       # save return address
   sw    $s0, -8($fp)       # save $s0 to use as ... n;
   addi  $sp, $sp, -12      # reset $sp to last pushed item

   # code for recursive fac()
# ... TODO ...
   
   li    $s0, 1
top_if:

   bgt   $a0, $s0, else     # if(n > 1)
   li    $v0, 1             # return 1;
   j     end
  
else: 
   move  $s0, $a0           # store n in $s0
   addi  $a0, $a0, -1       # n = n - 1;
   jal   fac                # calling the function fac(n-1)
   mult  $v0, $s0           # return n * fac(n-1)
   mflo  $v0                
   
   # clean up stack frame
# ... TODO ...   
end:

   lw    $s0, -8($fp)       # restore $s0 value
   lw    $ra, -4($fp)       # restore $ra for return
   la    $sp, 4($fp)        # restore $sp (remove stack frame)
   lw    $fp, ($fp)         # restore $fp (remove stack frame)

   jr    $ra                # return tmp;
