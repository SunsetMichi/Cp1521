# main program + show function

   .data
msg1:
   .asciiz "The matrix\n"
msg2:
   .asciiz "is an identity matrix\n"
msg3:
   .asciiz "is not an identity matrix\n"
   .align  2

   .text
   .globl main
main:
   addi $sp, $sp, -4
   sw   $fp, ($sp)
   la   $fp, ($sp)
   addi $sp, $sp, -4
   sw   $ra, ($sp)
   addi $sp, $sp, -4
   sw   $s1, ($sp)

   la   $a0, m        # store the matrix in $a0
   lw   $a1, N        # $a1 = N
   jal  is_ident      # s1 = is_ident(m,N)
   move $s1, $v0      # store return value of is_ident(m,N) in $s1

   la   $a0, msg1     
   li   $v0, 4
   syscall            # printf("The matrix\n")
   la   $a0, m
   lw   $a1, N
   jal  showMatrix    # showMatrix(m, N)

main_if:              # if (s1)
   beqz $s1, main_else
   la   $a0, msg2
   li   $v0, 4
   syscall            # printf("is an identity matrix\n")
   j    end_main_if

main_else:            # else
   la   $a0, msg3
   li   $v0, 4
   syscall            # printf("is not an identity matrix\n")

end_main_if:
   lw   $s1, ($sp)
   addi $sp, $sp, 4
   lw   $ra, ($sp)
   addi $sp, $sp, 4
   lw   $fp, ($sp)
   addi $sp, $sp, 4
   j    $ra

# end main()

# void showMatrix(m, N)
# params: m=$a0, N=$a1
# locals: m=$s0, N=$s1, row=$s2, col=$s3
showMatrix:
   addi $sp, $sp, -4
   sw   $fp, ($sp)
   la   $fp, ($sp)
   addi $sp, $sp, -4
   sw   $ra, ($sp)
   addi $sp, $sp, -4
   sw   $s0, ($sp)
   addi $sp, $sp, -4
   sw   $s1, ($sp)
   addi $sp, $sp, -4
   sw   $s2, ($sp)
   addi $sp, $sp, -4
   sw   $s3, ($sp)

   move $s0, $a0
   move $s1, $a1
   li   $s2, 0
show_matrix_loop1:
   bge  $s2, $s1, end_show_matrix_loop1

   li   $s3, 0
show_matrix_loop2:
   bge  $s3, $s1, end_show_matrix_loop2

   li   $a0, ' '          # putchar(' ')
   li   $v0, 11
   syscall

   move $t0, $s2
   mul  $t0, $t0, $s1
   add  $t0, $t0, $s3
   li   $t1, 4
   mul  $t0, $t0, $t1
   add  $t0, $t0, $s0
   lw   $a0, ($t0)
   li   $v0, 1            # printf("%d",m[row][col])
   syscall

   addi $s3, $s3, 1       # col++
   j    show_matrix_loop2

end_show_matrix_loop2:
   li   $a0, '\n'         # putchar('\n')
   li   $v0, 11
   syscall

   addi $s2, $s2, 1       # row++
   j    show_matrix_loop1

end_show_matrix_loop1:

   lw   $s3, ($sp)
   addi $sp, $sp, 4
   lw   $s2, ($sp)
   addi $sp, $sp, 4
   lw   $s1, ($sp)
   addi $sp, $sp, 4
   lw   $s0, ($sp)
   addi $sp, $sp, 4
   lw   $ra, ($sp)
   addi $sp, $sp, 4
   lw   $fp, ($sp)
   addi $sp, $sp, 4
   j    $ra

   .text
   .globl is_ident

# params: m=$a0, n=$a1
is_ident:
# prologue
   addi $sp, $sp, -4
   sw   $fp, ($sp)
   la   $fp, ($sp)
   addi $sp, $sp, -4
   sw   $ra, ($sp)
   addi $sp, $sp, -4
   sw   $s0, ($sp)
   addi $sp, $sp, -4
   sw   $s1, ($sp)
   addi $sp, $sp, -4
   sw   $s2, ($sp)
   addi $sp, $sp, -4
   sw   $s3, ($sp)
   # if you need to save more than four $s? registers
   # add extra code here to save them on the stack

# ... your code for the body of is_ident(m,N) goes here ...
    
   move $s0, $a0        # storing the matrix into $s0
   move $s1, $a1        # $s1 = N
   li   $s2, 0          # $s2 = row = 0
   
is_ident_loop1:
   bge  $s2, $s1, end_is_ident_loop1    # if(row >= n) jump to end loop
   li   $s3, 0                          # col = 0

is_ident_loop2:
   bge  $s3, $s1, end_is_ident_loop2    # if(col >= n) goto loop1

   move $t0, $s2                        # $t0 = row
   mul  $t0, $t0, $s1                   # $t0 = $t0 * n
   add  $t0, $t0, $s3                   # $t0 = $t0 * col
   li   $t1, 4                          # $t1 = 4 because int are 4 bytes
   mul  $t0, $t0, $t1                   # $t0 = $t0 * 4
   add  $t0, $t0, $s0                   # matrix[row][col] += $s0
   lw   $t1, ($t0)                      # $t1 = m[row][col]
  
   j    is_ident_if1

end_is_ident_loop1:
   li   $v0, 1
   j    end

end_is_ident_loop2:
   addi $s2, $s2, 1                     # row++
   j    is_ident_loop1

is_ident_if1:
   bne  $s2, $s3, is_ident_else         # if(row != col) jump to else
   j    is_ident_if2
   
is_ident_else:
   beqz $t1, add_loop2                  # if (m[row][col] == 0) 
   li   $v0, 0
   j    end
   
is_ident_if2:
   li   $t2, 1                          # $t2 = 1
   beq  $t1, $t2, add_loop2             # if (m[row][col] == 1 ) goto loop2            
   li   $v0, 0
   j    end
   
add_loop2:
   addi $s3, $s3, 1                     # col++;
   j    is_ident_loop2

end:
# epilogue
   # if you saved more than four $s? registers
   # add extra code here to restore them
   lw   $s3, ($sp)
   addi $sp, $sp, 4
   lw   $s2, ($sp)
   addi $sp, $sp, 4
   lw   $s1, ($sp)
   addi $sp, $sp, 4
   lw   $s0, ($sp)
   addi $sp, $sp, 4
   lw   $ra, ($sp)
   addi $sp, $sp, 4
   lw   $fp, ($sp)
   addi $sp, $sp, 4
   j    $ra

# COMP1521 18s1 Exam Q1
# Matrix data

   .data
N:
   .word   9
m:
   .word   1, 0, 0, 0, 0, 0, 0, 0, 0
   .word   0, 1, 0, 0, 0, 0, 0, 0, 0
   .word   0, 0, 1, 0, 0, 0, 0, 0, 0
   .word   0, 0, 0, 1, 0, 0, 0, 0, 0
   .word   0, 0, 0, 0, 1, 0, 0, 0, 0
   .word   0, 0, 0, 0, 0, 1, 0, 0, 0
   .word   0, 0, 0, 0, 0, 0, 1, 0, 0
   .word   0, 0, 0, 0, 0, 0, 0, 1, 0
   .word   0, 0, 0, 0, 0, 0, 0, 0, 1

   .align  2
