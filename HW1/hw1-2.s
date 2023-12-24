.globl __start

.rodata
    msg0: .string "This is HW1-2: \n"
    msg1: .string "Enter shift: "
    msg2: .string "Plaintext: "
    msg3: .string "Ciphertext: "
.text

################################################################################
  # print_char function
  # Usage: 
  #     1. Store the beginning address in x20
  #     2. Use "j print_char"
  #     The function will print the string stored from x20 
  #     When finish, the whole program with return value 0

print_char:
    addi a0, x0, 4
    la a1, msg3
    ecall
  
    add a1,x0,x20
    ecall

  # Ends the program with status code 0
    addi a0,x0,10
    ecall
    
################################################################################

__start:
  # Prints msg
    addi a0, x0, 4
    la a1, msg0
    ecall

  # Prints msg1
    addi a0, x0, 4
    la a1, msg1
    ecall
  # Reads an int
    addi a0, x0, 5
    ecall
    add a6, a0, x0
    
  # Prints msg2
    addi a0, x0, 4
    la a1, msg2
    ecall
    
    addi a0,x0,8
    li a1, 0x10150
    addi a2,x0,2047
    ecall
  # Load address of the input string into a0
    add a0,x0,a1


################################################################################ 
  # Write your main function here. 
  # a0 stores the begining Plaintext
  # x16 stores the shift
  # Do store 66048(0x10200) into x20 
  # ex. j print_char
  
  # save the following used constant : a4 = 26, a5 = 10, a7 = 32, s2 = 48
  addi a4, zero, 26
  addi a5, zero, 10
  addi a7, zero, 32
  addi s2, zero, 48
  # s0 save i = 0
  add s0, zero, zero
  # save j = 0 in s1
  li s1, 0
  
  loop:
  # address of plaintext y[i] in a3
  add a3, s0, a0
  # a1 = y[i]
  lb a1, 0(a3)
  # set address of ciphertext x 66048(0x10200) into x20
  li x20, 66048
  # address of ciphertext x[i] in a2
  add a2, x20, s0
  # check terminate. If a1 = "\n", then finishing the loop.
  beq a1, a5, done
  # check space
  beq a1, a7, space
  
  # apply caeser cypher
  addi a1, a1, -97
  add a1, a1, x16
  blt a1, zero, correction
  # do a1 mod (26)
  remu a1, a1, a4
  j continue
  
  correction:
  addi a1, a1, 26
  
  continue:
  addi a1, a1, 97
  # x[i] = y[i]
  sb a1, 0(a2) 
  # i = i + 1
  addi s0, s0, 1
  j loop
  
  space:
  # let y[i] = 0,1,2.....
  add a1, s1, s2
  sb a1, 0(a2) 
  # i = i + 1
  addi s0, s0, 1
  # j = j + 1
  addi s1, s1, 1
  j loop
  
  done:
  j print_char
   
################################################################################