############################################################ -*- asm -*-
# CP1521  -- Assignment 1 -- Scrolling Text!
# Scroll letters from a message in argv[1]
#
# Base code by Jashank Jeremy
# Tweaked by John Shepherd
# $Revision: 1.5 $
#
# Edit me with 8-column tabs!

# Requires:
#  - `all_chars', defined in chars.s

# Provides:
	.globl	main # :: int, [char *], [char *] -> int
	.globl	setUpDisplay # :: int, int -> void
	.globl	showDisplay # :: void -> void
	.globl	delay # :: int -> vovid
	.globl	isUpper # :: char -> int
	.globl	isLower # :: char -> int

	.globl	CHRSIZE
	.globl	NROWS
	.globl	NDCOLS
	.globl	MAXCHARS
	.globl	NSCOLS
	.globl	CLEAR


########################################################################
	.data

	# /!\ NOTE /!\
	# In C, the values of the symbols `CHRSIZE', `NROWS', `NDCOLS',
	# `NSCOLS', `MAXCHARS', and `CLEAR' would be substituted during
	# preprocessing.  SPIM does not have preprocessing facilities,
	# so instead we provide these values in the `.data' segment.

	# # of rows and columns in each big char
CHRSIZE:	.word	9
	# number of rows in all matrices
NROWS:		.word	9
	# number of columns in display matrix
NDCOLS:		.word	80
	# max length of input string
MAXCHARS:	.word	100
	# number of columns in bigString matrix
	# max length of buffer to hold big version
	# the +1 allows for one blank column between letters
NSCOLS:		.word	9000	# (NROWS * MAXCHARS * (CHRSIZE + 1))
        # ANSI escape sequence for 'clear-screen'
CLEAR:	.asciiz "\033[H\033[2J"
# CLEAR:	.asciiz "__showpage__\n" # for debugging
newLine:    .asciiz "\n"
main__0:	.asciiz	"Usage: ./scroll String\n"
main__1:	.asciiz	"Only letters and spaces are allowed in the string!\n"
main__2:	.asciiz "String must be < "
main__3:	.asciiz " chars\n"
main__4:	.asciiz "Please enter a string with at least one character!\n"
#newLine:    .asciiz "\n"

	.align	4
theString:	.space	101	# MAXCHARS + 1
	.align	4
display:	.space	720	# NROWS * NDCOLS
	.align	4
bigString:	.space	81000	# NROWS * NSCOLS


########################################################################
# .TEXT <main>
	.text
main:

# Frame:	$fp, $ra
# Uses:		$a0, $a1, $t0, $t1, $t2, $s0, $s1
# Clobbers:	$t1, $t2, $t3, $t4, $t5, $t6, $t7

# Locals:
#	- `theLength' in $s0
#	- `bigLength' in $s1
#	- `ch' in $s2
#	- `str' in $t2
#	- `i' in $s3
#	- `j' in $t3
#	- `row' in $t4
#	- `col' in $t5
#	- `iterations' in $s7
#	- `startingCol' in $s6

# Structure:
#	main
#	-> [prologue]
#	-> main_argc_gt_two
#	-> main_PTRs_init
#	  -> main_PTRs_cond
#	    -> main_ch_notspace
#	    -> main_ch_isLower
#	    -> main_ch_isSpace
#	  -> main_PTRs_step
#	-> main_PTRs_f
#	[theLength cond]
#	  | main_theLength_ge_MAXCHARS
#	  | main_theLength_lt_MAXCHARS
#	  | main_theLength_lt_1
#	  | main_theLength_ge_1
#	...
#	-> [epilogue]

# Code:
	# set up stack frame
	sw	$fp, -4($sp)
	la	$fp, -4($sp)
	sw	$ra, -4($fp)  # note: switch to $fp-relative
	sw	$s0, -8($fp)
	sw	$s1, -12($fp)
	sw	$s2, -16($fp)
	sw  $s3, -20($fp)
	sw  $s4, -24($fp)
	sw  $s5, -28($fp)
	sw  $s6, -32($fp)
	sw  $s7, -36($fp)
	addi	$sp, $sp, -40

	# if (argc < 2)
	li	$t0, 2
	bge	$a0, $t0, main_argc_gt_two
	nop	# in delay slot
	# printf(...)
	la	$a0, main__0
	li	$v0, 4 # PRINT_STRING_SYSCALL
	syscall
	# return 1  =>  load $v0, jump to epilogue
	li	$v0, 1
	j	main__post
	nop	# in delay slot
main_argc_gt_two:

	move	$s0, $zero
main_PTRs_init:
	# s = argv[1]
	lw	$t2, 4($a1)
main_PTRs_cond:
	# optimisation: `ch = *s' now
	# (ch = )*s
	lb	$s2, ($t2)
	# *s != '\0'  =>  ch != 0
	beqz	$s2, main_PTRs_f
	nop	# in delay slot

	# if (!isUpper(ch))
main_ch_upper:
	move	$a0, $s2
	jal	isUpper
	nop	# in delay slot
	beqz	$v0, main_ch_lower
	nop	# in delay slot
	j	main_ch_ok
	nop	# in delay slot
	# if (!isLower(ch))
main_ch_lower:
	move    $a0, $s2
	jal	isLower
	nop	# in delay slot
	beqz	$v0, main_ch_space
	nop	# in delay slot
	j	main_ch_ok
	nop	# in delay slot
	# if (ch != ' ')
main_ch_space:
	li	$t0, ' '
	bne	$s2, $t0, main_ch_fail
	nop	# in delay slot
	j	main_ch_ok
	nop	# in delay slot

main_ch_fail:
	# printf(...)
	la	$a0, main__1
	li	$v0, 4 # PRINT_STRING_SYSCALL
	syscall
	# exit(1)  =>  return 1  =>  load $v0, jump to epilogue
	li	$v0, 1
	j	main__post
	nop	# in delay slot

main_ch_ok:
	# if (theLength >= MAXCHARS)
	la	$t0, MAXCHARS
	lw	$t0, ($t0)
	# break  =>  jump out of for(*s...)
	bge	$s0, $t0, main_PTRs_f

	# theString[theLength]
	la	$t0, theString
	addu	$t0, $t0, $s0	# ADDU because address
	# theString[theLength] = ch
	sb	$s2, ($t0)

	# theLength++
	addi	$s0, $s0, 1

main_PTRs_step:
	# s++  =>  s = s + 1
	addiu	$t2, $t2, 1	# ADDIU because address
	j	main_PTRs_cond
	nop
main_PTRs_f:

	# theString[theLength] = ...
	la	$t0, theString
	addu	$t0, $t0, $s0	# ADDU because address
	# theString[theLength] = '\0'
	sb	$zero, ($t0)

	# CHRSIZE + 1
	la	$t0, CHRSIZE
	lw	$t0, ($t0)
	addi	$t0, $t0, 1
	# bigLength = theLength * (CHRSIZE + 1)
	mul	$s1, $t0, $s0

	# if (theLength >= MAXCHARS)
	la	$t0, MAXCHARS
	lw	$t0, ($t0)
	blt	$s0, $t0, main_theLength_lt_MAXCHARS
	nop	# in delay slot
main_theLength_ge_MAXCHARS:
	# printf(..., ..., ...)
	la	$a0, main__2
	li	$v0, 4 # PRINT_STRING_SYSCALL
	syscall
	move	$a0, $t0
	li	$v0, 1 # PRINT_INT_SYSCALL
	syscall
	la	$a0, main__3
	li	$v0, 4 # PRINT_STRING_SYSCALL
	syscall
	# return 1  =>  load $v0, jump to epilogue
	li	$v0, 1
	j	main__post
	nop	# in delay slot
main_theLength_lt_MAXCHARS:

	# if (theLength < 1)
	li	$t0, 1
	bge	$s0, $t0, main_theLength_ge_1
	nop	# in delay slot
main_theLength_lt_1:
	# printf(...)
	la	$a0, main__4
	li	$v0, 4 # PRINT_STRING_SYSCALL
	syscall
	# exit(1)  =>  return 1  =>  load $v0, jump to epilogue
	li	$v0, 1
	j	main__post
	nop	# in delay slot
main_theLength_ge_1:
	# ... TODO ...
	# Setting up variables
	# $t0 = NROWS; $t1 = NDCOLS; $s3 = i; $s5 = ' '; $s7 = NSCOLS;
    la  $t0, NROWS                             
    lw  $t0, ($t0)
    la  $t1, NDCOLS                             
    lw  $t1, ($t1)
    li  $s3, 0                                  
    li  $s5, ' '
    la  $s7, NSCOLS
    lw  $s7, ($s7)
main_ini_loop1:
    # if(i >= NROWS) goto array_loop
    bge $s3, $t0, end_ini_loop1     
    # j = 0, $t4 = j            
    li  $t3, 0                                  
    
main_ini_loop2:
    # if(j >= NDCOLS) goto end_loop2
    bge $t3, $t1, end_ini_loop2    
    
    # offset = i * NDCOLS + j             
    mul $t4, $s3, $t1                           
    add $t4, $t4, $t3 
    # display[i][j] = ' '                                     
	sb  $s5, display($t4) 
	  
	# j++					        
    addi    $t3, $t3, 1                        
    j   main_ini_loop2

end_ini_loop2:
    # i++
    addi    $s3, $s3, 1                         
    j   main_ini_loop1

# Create the bigchars array
end_ini_loop1:
    # i = 0, $t3 = i
    li  $s3, 0      
    # $s4 = CHRSIZE                            
    la  $s4, CHRSIZE                            
    lw  $s4, ($s4)
    
main_create_loop1:
    # if(i >= theLength) goto end
    bge $s3, $s0, end_create_loop1
    
    # ch = theString[i]              
    lb  $t1, theString($s3)        
    move    $s2, $t1                              
    
if_is_space:
    # if(ch != ' ') goto if_is_upper
    bne $s2, $s5, if_is_upper 
          
    # row = 0             
    li  $t4, 0                                  
    
main_create_loop2:
    # if (row >= CHRSIZE) goto end_create_loop2
    bge $t4, $s4, end_create_loop2  
    
    # col = 0            
    li  $t5, 0                                  
    
main_create_loop3:
    # if (col >= CHRSIZE)
    bge $t5, $s4, end_create_loop3  
    
    # offset = (row * NSCOLS) + (col + i * (CHRSIZE + 1))           
    mul $t6, $t4, $s7          
    addi    $t7, $s4, 1                         
    mul $t7, $t7, $s3
    add $t7, $t7, $t5
    add $t6, $t6, $t7  
    # bigString[...][...] = ' '                 
    sb  $s5, bigString($t6)
    
    # col++
    addi    $t5, $t5, 1                        
    j   main_create_loop3
    
end_create_loop3:
    # row++
    addi    $t4, $t4, 1                        
    j   main_create_loop2    

end_create_loop2:   
    j   end_if_else

else_ch_is_not_space: 
if_is_upper:
    # if(!isUpper(ch)) goto if_is_lower
    move    $a0, $s2                           
    jal isUpper
    beqz    $v0, if_is_lower 
      
    # which = ch - 'A'                
    li  $t6, 'A'                                
    sub $t6, $s2, $t6     
    j   else_loops                      
    
if_is_lower:
    # which = ch - 'a' + 26
    li  $t6, 'a'                                
    sub $t6, $s2, $t6                           
    addi    $t6, $t6, 26

else_loops:
    # row = 0
    li  $t4, 0                                  
    
else_loop1:
    # if (row >= CHRSIZE) goto end_else_loop1
    bge $t4, $s4, end_else_loop1 
        
    # col = 0           
    li  $t5, 0                                  

else_loop2:
    # if (col >= CHRSIZE) goto end_else_loop2
    bge $t5, $s4, end_else_loop2     
               
    # offset of bigString = row * NSCOLS + col + i * (CHRSIZE+1)
    mul $t7, $t4, $s7                           
    addi    $t8, $s4, 1                        
    mul $t8, $t8, $s3
    add $t8, $t8, $t5
    add $t8, $t8, $t7
    la  $t1, bigString                          
    add $t1, $t1, $t8
    
    # offset of all_chars = which * 81 + row * NROWS + col
    li  $t8, 81
    mul $t8, $t6, $t8                          
    mul $t7, $t4, $t0                           
    add $t7, $t7, $t5
    add $t7, $t7, $t8
    la  $t9, all_chars
    add $t7, $t7, $t9
    
    # bigString[row][col + i * (CHRSIZE+1)] = all_chars[which][row][col]
    lb  $t7, ($t7)
    sb  $t7, ($t1)                              

    # col++
    addi    $t5, $t5, 1                        
    j   else_loop2
    
end_else_loop2:
    # row++
    addi    $t4, $t4, 1                        
    j   else_loop1
end_else_loop1:
    j   end_if_else

end_if_else:
    # col = (i * (CHRSIZE+1)) + CHRSIZE
	move    $t8, $s4							
	addi    $t8, $t8, 1
	mul	$t8, $t8, $s3
	add	$t8, $t8, $s4
	move    $t5, $t8
	
	# row = 0
	li	$t4, 0									

end_if_else_loop1:
    # if (row >= CHRSIZE) goto end_end_if_else_loop1
	bge	$t4, $s4, end_end_if_else_loop1	
		
	# calculate offset and bigString[row][col] = ' '		
	mul	$t8, $t4, $s7							 
	add	$t8, $t8, $t5
	sb	$s5, bigString($t8)	
	
	# row++						
	addi    $t4, $t4, 1						
	j	end_if_else_loop1				

end_end_if_else_loop1:
    # i++
    addi    $s3, $s3, 1                        
    j   main_create_loop1
    
end_create_loop1:
    # $t1 = NDCOLS
	la	$t1, NDCOLS								
	lw	$t1, ($t1)	
	# iterations = NDCOLS + bigLength
	add	$s7, $s1, $t1	
	# starting_col = NDCOLS - 1						
	add	$s6, $t1, -1		
	# i = 0					
	li	$s3, 0									

last_main_loop:
    # if(i >= iterations) goto_last_main_loop
	bge	$s3, $s7, end_last_main_loop			
	move    $a0, $s6
	move    $a1, $s1
	
	# setUpDisplay(starting_col, bigLength)
	jal	setUpDisplay	
	# showDisplay()						
	jal	showDisplay	
	# starting_col--							
	sub	$s6, $s6, 1								
	la	$a0, 1	
	# delay(1)								
	jal	delay	
	
	# i++
	addi    $s3, $s3, 1						
	j	last_main_loop
	
end_last_main_loop:
    # return 0
	move	$v0, $zero

main__post:
	# tear down stack frame
	lw  $s7, -36($fp)
	lw  $s6, -32($fp)
	lw  $s5, -28($fp)
	lw  $s4, -24($fp)
	lw  $s3, -20($fp)
	lw	$s2, -16($fp)
	lw	$s1, -12($fp)
	lw	$s0, -8($fp)
	lw	$ra, -4($fp)
	la	$sp, 4($fp)
	lw	$fp, ($fp)
	jr	$ra
	nop	# in delay slot

########################################################################
# .TEXT <setUpDisplay>
	.text
setUpDisplay:

# Frame:	$fp, $ra
# Uses:		$a0, $a1, $t0, $t1, $t2, $t3, $t4, $t5, $t6, $t7 
# Clobbers:	$t0, $t1, $t2, $t3, $t4, $t5, $t6, $t7 

# Locals:
#	- NROWS in $t0
#	- NDCOLS in $t1
#	- `row' in $t2
#	- `out_col' in $t3
#	- 'first_col' in $t4
#	- 'in_col' in $t5

# Structure:
#	setUpDisplay
#	-> [prologue]
#	-> ...
#	-> [epilogue]

# Code:
	# set up stack frame
	sw	$fp, -4($sp)
	la	$fp, -4($sp)
	sw	$ra, -4($fp)
	la	$sp, -8($fp)

	# ... TODO ...
	# $t0 = NROWS
	la  $t0, NROWS                  
	lw  $t0, ($t0)
	# $t1 = NDCOLS
	la  $t1, NDCOLS
	lw  $t1, ($t1)  
	                
	# if (starting >= 0) goto else_bge_0
	bgez    $a0, else_bge_0  
	
	# out_col = 0      
	li  $t3, 0                      
	li  $t4, -1
	# first_col = -starting
	mul $t4, $t4, $a0               
	j   setUp_copy

else_bge_0:
    # out_col = 0
    li  $t3, 0                      
    
else_blank_loop1:
    # if (out_col >= starting) goto end_blank_loop1
    bge $t3, $a0, end_blank_loop1   
    # row = 0
    li  $t2, 0                      
    
else_blank_loop2:
    # if (row >= NROWS) goto end_blank_loop2
    bge $t2, $t0, end_blank_loop2  
    
    # offset of display = row * NDCOLS + out_col 
    mul $t6, $t2, $t1               
    add $t6, $t6, $t3
    li  $t7, ' '  
    # display[row][out_col] = ' '               
    sb  $t7, display($t6)           

    # row++
    addi    $t2, $t2, 1            
    j   else_blank_loop2

end_blank_loop2:
    # out_col++
    addi    $t3, $t3, 1            
    j   else_blank_loop1
    
end_blank_loop1:
    # first_col = 0      
    li  $t4, 0                       
    
setUp_copy:
    # in_col = first_col
    move    $t5, $t4               
       
setUp_copy_loop1:
    # if (in_col >= length) goto end_setUp_Display
    bge $t5, $a1, end_setUpDisplay  
    
if_outCol_NDCOLS:
    # if (out_col < NDCOLS)
    bge $t3, $t1, end_setUpDisplay  
    
    # row = 0
    li  $t2, 0                      
    
setUp_copy_loop2:
    # if (row >= NROWS) goto end_setUp_loop2
    bge $t2, $t0, end_setUp_loop2   
    
    # offset of display = row * NDCOLS + out_col
    mul $t6, $t2, $t1               
    add $t6, $t6, $t3
    
    # $t9 = NSCOLS
    la  $t9, NSCOLS                 
    lw  $t9 ,($t9)
    
    # offset of bigString = row * NSCOLS + in_col
    mul $t7, $t2, $t9               
    add $t7, $t7, $t5   
    
    #  display[row][out_col] = bigString[row][in_col]
    lb  $t8, bigString($t7)                  
    sb  $t8, display($t6)
     
    # row++
    addi    $t2, $t2, 1            
    j   setUp_copy_loop2

end_setUp_loop2:
    # out_col++
    addi     $t3, $t3, 1
    # in_col++            
    addi     $t5, $t5, 1            
    j   setUp_copy_loop1

end_setUpDisplay:
	# tear down stack frame
	lw	$ra, -4($fp)
	la	$sp, 4($fp)
	lw	$fp, ($fp)
	jr	$ra
	nop	# in delay slot

########################################################################
# .TEXT <showDisplay>
	.text
showDisplay:

# Frame:	$fp, $ra
# Uses:		$a0, $v0, $t0, $t1, $t2, $t3, $t4, $t5
# Clobbers:	$t0, $t1, $t2, $t3, $t4

# Locals:
#	- `i' in $t2
#	- `j' in $t3
#	- 'NROWS' in $t0
#   - 'NDCOLS' in $t1

# Structure:
#	showDisplay
#	-> [prologue]
#	-> ...
#	-> [epilogue]

# Code:
	# set up stack frame
	sw	$fp, -4($sp)
	la	$fp, -4($sp)
	sw	$ra, -4($fp)
	la	$sp, -8($fp)

	# ... TODO ...
	# printf(CLEAR)
    li	$v0, 4
	la	$a0, CLEAR						
	syscall
	
	# $t0 = NROWS
	la  $t0, NROWS                      
	lw  $t0, ($t0)
	# $t1 = NDCOLS
	la  $t1, NDCOLS
	lw  $t1, ($t1)  
	
	# i = 0                    
	li  $t2, 0                          
	
showDisplay_loop1:
    # if(i >= NROWS) goto end_showDisplay
    bge $t2, $t0, end_showDisplay 
    
    # j = 0      
    li  $t3, 0                          

showDisplay_loop2:
    # if(j >= NDCOLS) goto end_showD_loop2
    bge $t3, $t1, end_showD_loop2    
    
    # offset of display = i * NDCOLS + j   
    mul $t4, $t2, $t1                   
    add $t4, $t4, $t3
    
    # putchar(display[i][j])
    li  $v0, 11                         
    lb  $a0, display($t4)
    syscall 
    
    # j++
    addi    $t3, $t3, 1                
    j   showDisplay_loop2
    
end_showD_loop2:
    # putchar('\n')
    li  $v0, 4                         
    la  $a0, newLine
    syscall
    
    # i++
    addi    $t2, $t2, 1                
    j   showDisplay_loop1
    
end_showDisplay:
	# tear down stack frame
	lw	$ra, -4($fp)
	la	$sp, 4($fp)
	lw	$fp, ($fp)
	jr	$ra
	nop	# in delay slot

########################################################################
# .TEXT <delay>
	.text
delay:

# Frame:	$fp, $ra
# Uses:		$a0, $t0, $t1, $t2, $t3, $t4, $t5
# Clobbers:	$t0, $t1, $t2, $t3, $t4, $t5

# Locals:
#	- `n' in $a0
#	- `x' in $t0
#	- `i' in $t1
#	- `j' in $t2
#	- `k' in $t3

# Structure:
#	delay
#	-> [prologue]
#	-> delay_i_init
#	-> delay_i_cond
#	   -> delay_j_init
#	   -> delay_j_cond
#	      -> delay_k_init
#	      -> delay_k_cond
#	         -> delay_k_step
#	      -> delay_k_f
#	      -> delay_j_step
#	   -> delay_j_f
#	   -> delay_i_step
#	-> delay_i_f
#	-> [epilogue]

# Code:
	sw	$fp, -4($sp)
	la	$fp, -4($sp)
	sw	$ra, -4($fp)
	la	$sp, -8($fp)

	# x <- 0
	move	$t0, $zero
	# These values control the busy-wait.
	li	$t4, 80
	li	$t5, 80

delay_i_init:
	# i = 0;
	move	$t1, $zero
delay_i_cond:
	# i < n;
	bge	$t1, $a0, delay_i_f
	nop	# in delay slot

delay_j_init:
	# j = 0;
	move	$t2, $zero
delay_j_cond:
	# j < DELAY_J;
	bge	$t2, $t4, delay_j_f
	nop	# in delay slot

delay_k_init:
	# k = 0;
	move	$t3, $zero
delay_k_cond:
	# k < DELAY_K;
	bge	$t3, $t5, delay_k_f
	nop	# in delay slot

	# x = x + 1
	addi	$t0, $t0, 1

delay_k_step:
	# k = k + 1
	addi	$t3, $t3, 1
	j	delay_k_cond
	nop	# in delay slot
delay_k_f:

delay_j_step:
	# j = j + 1
	addi	$t2, $t2, 1
	j	delay_j_cond
	nop	# in delay slot
delay_j_f:

delay_i_step:
	# i = i + 1
	addi	$t1, $t1, 1
	j	delay_i_cond
	nop	# in delay slot
delay_i_f:

delay__post:
	# tear down stack frame
	lw	$ra, -4($fp)
	la	$sp, 4($fp)
	lw	$fp, ($fp)
	jr	$ra
	nop	# in delay slot

########################################################################
# .TEXT <isUpper>
	.text
isUpper:

# Frame:	$fp, $ra
# Uses:		$a0
# Clobbers:	$v0

# Locals:
#	- 'ch' in $a0
#	- ...$v0 used as temporary register

# Structure:
#	isUpper
#	-> [prologue]
#	-> [epilogue]

# Code:
	# set up stack frame
    sw	$fp, -4($sp)
	la	$fp, -4($sp)
	sw	$ra, -4($fp)
	la	$sp, -8($fp)
	
	# ... TODO ...
	# if(ch < 'A')
	li  $v0, 'A'
	blt $a0, $v0, not_upper         
isUpper_smaller_Z:
    # if(ch > 'Z')
    li  $v0, 'Z'
    bge $a0, $v0, not_upper 
    
    # return 1        
    li  $v0, 1                      
    j   end
    
not_upper:
    li  $v0, 0
    j   end

end: 
	# tear down stack frame
    lw	$ra, -4($fp)
	la	$sp, 4($fp)
	lw	$fp, ($fp)
	jr	$ra
	nop	# in delay slot

########################################################################
# .TEXT <isLower>
	.text
isLower:

# Frame:	$fp, $ra
# Uses:		$a0
# Clobbers:	$v0

# Locals:
#	- `ch' in $a0
#	- ... $v0 used as temporary register

# Structure:
#	isLower
#	-> [prologue]
#	[ch cond]
#	   | isLower_ch_ge_a
#	   | isLower_ch_le_z
#	   | isLower_ch_lt_a
#	   | isLower_ch_gt_z
#	-> isLower_ch_phi
#	-> [epilogue]

# Code:
	# set up stack frame
	sw	$fp, -4($sp)
	la	$fp, -4($sp)
	sw	$ra, -4($fp)
	la	$sp, -8($fp)

	# if (ch >= 'a')
	li	$v0, 'a'
	blt	$a0, $v0, isLower_ch_lt_a
	nop	# in delay slot
isLower_ch_ge_a:
	# if (ch <= 'z')
	li	$v0, 'z'
	bgt	$a0, $v0, isLower_ch_gt_z
	nop	# in delay slot
isLower_ch_le_z:
	addi	$v0, $zero, 1
	j	isLower_ch_phi
	nop	# in delay slot

	# ... else
isLower_ch_lt_a:
isLower_ch_gt_z:
	move	$v0, $zero
	# fallthrough
isLower_ch_phi:

isLower__post:
	# tear down stack frame
	lw	$ra, -4($fp)
	la	$sp, 4($fp)
	lw	$fp, ($fp)
	jr	$ra
	nop	# in delay slot

#################################################################### EOF
