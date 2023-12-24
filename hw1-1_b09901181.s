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
  # ex. addi t0, a0, 
main:
    addi sp, sp, -12
    sw x1, 8(sp)      #x1 = return address
    sw x5, 4(sp)       #x5 = t0(output)
    sw x10, 0(sp)      #x10 = a0(input)
    addi x31, x0, 1    #x31 = 1
    bne x10 x31, l1
    addi x5, x0, 2     #T(1) = 2
    addi sp, sp, 12
    beq x1, x0, result
    jalr x0, 0(x1)
l1:
    addi x31, x0, 2    #x31 = 2
    div x10, x10, x31  #a0/2 (n/2)
    jal x1, main       #return n/2 
    add x7, x5, x0     #x7 = T(n/2)
    lw x10, 0(sp)
    lw x5, 4(sp)  
    lw x1, 8(sp)   
    add x31, x10, x0   #x31 = x10(n)
    addi x30, x0, 6    #x30 = 6
    mul x31, x31, x30  #x31 = 6n
    addi x31, x31, 4   #x31 = 6n+4
    addi x30, x0, 5    #x30 = 5
    mul x7, x30, x7    #x7 = 5T(n/2)
    add x5, x7, x31    #x5 = 5T(n/2) + 6n + 4
    addi sp,sp, 12
    beq x1, x0, result
    jalr x0, 0(x1)  
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