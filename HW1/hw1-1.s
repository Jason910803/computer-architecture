.globl __start

.rodata
    msg0: .string "This is HW1-1: T(n) = 5T(n/2) + 6n + 4, T(1) = 2\n"
    msg1: .string "Enter a number: "
    msg2: .string "The result is: "

.text


__start:
  # Prints msg0
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

################################################################################ 
  # Write your main function here. 
  # Input n is in a0. You should store the result T(n) into t0
  # HW1-1 T(n) = 5T(n/2) + 6n + 4, T(1) = 2, round down the result of division
  # ex. addi t0, a0, 1
  
    jal T
    # store output a2 into t0
    addi t0, a2, 0
    # print the result
    j result
T:
    # open two stack to save return address ra and a0(n)
    addi sp, sp, -8
    sw ra, 4(sp)
    sw a0, 0(sp)
    # when n greater or equal than 2, then jump to L1
    slti t0, a0, 2
    beq t0, zero, L1
    # set return value a2 to 2
    addi a2, zero, 2
    # pop stack
    addi sp, sp, 8
    # back to return address
    jr ra
L1:
    # n = floor(n / 2)
    srai a0, a0, 1
    # call T(floor(n/2))
    jal T
    # restore return address ra and a0(n)
    lw a0, 0(sp)
    lw ra, 4(sp)
    # pop stack
    addi sp, sp, 8
    # return T(n) = 5T(n/2) + 6n + 4
    addi a3, zero, 5
    mul a2, a2, a3
    addi a4, zero, 6
    mul a0, a0, a4
    add a2, a2, a0
    addi a2, a2, 4
    # back to return address
    jr ra
    
################################################################################

result:
  # Prints msg2
    addi a0, x0, 4
    la a1, msg2
    ecall

  # Prints the result in t0
    addi a0, x0, 1
    add a1, x0, t0
    ecall
    
  # Ends the program with status code 0
    addi a0, x0, 10
    ecall