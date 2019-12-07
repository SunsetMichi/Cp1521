#percentage.s 
#Read in two integers: 
#the total number of marks in the exam, 
#and how many marks the student was awarded.
#Print out what percentage of the marks the student was awarded for that exam
#with no decimal places.

#int max;
#int mark;
#int main(void){
#    printf("Enter the total number of marks in the exam: ");
#    scanf("%d",&max);
#    printf("Enter the number of marks the student was awarded: ");
#    scanf("%d",&mark);
#
#    printf("The student scored %d%% in this exam.\n",100*mark/max);
#    return 0;
#}

          .data
max:    .space 4      #int max
mark:   .space 4      #int mark
          
ask_max:  .asciiz "Enter the total number of marks in the exam: "
ask_mark: .asciiz "Enter the number of marks the student was awarded: "
score1:   .asciiz "The student scored "
score2:   .asciiz "% in this exam.\n"
newline:  .asciiz "\n"

#TODO add more here if needed

      .text
      .globl main
main:
      li    $v0, 4
      la    $a0, ask_max       # load address of ask_max in $a0
      syscall                  # printf("Enter the total number of marks in the exam: ");       

      #TODO finish implementing code 

      li    $v0, 5
      syscall                  # scanf("%d",&max);
      sw    $v0, max           # max = $v0   

      li    $v0, 4
      la    $a0, ask_mark      # load address of ask_mark in $a0
      syscall                  # printf("Enter the number of marks the student was awarded: ");
      
      li    $v0, 5
      syscall                  # scanf("%d",&mark);
      sw    $v0, mark    
        
      la    $a0, score1        
      li    $v0, 4
      syscall                  # printf("The student scored ");
      
      lw    $s0, max           # $s0 = max
      lw    $s1, mark          # $s1 = mark
      li    $t0, 100           # $t0 = 100; 
      mul   $a0, $s1, $t0      # $a0 = mark*100;
      div   $a0, $a0, $s0      # $a0 = mark*100/max;
      
      li    $v0, 1             
      syscall                  # printf("%d",100*mark/max);
        
      la    $a0, score2        
      li    $v0, 4
      syscall                  #printf("% in this exam.\n");
        
      li    $v0, 0             # set return value to 0
      jr    $ra                # return from main
