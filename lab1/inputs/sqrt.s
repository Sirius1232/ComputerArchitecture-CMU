main:
    addiu   $2, $zero, 123456
    addiu   $3, $zero, 1
    addiu   $4, $zero, 0
judge:
    beq     $2, $zero, output
loop:
    sub     $2, $2, $3
    addi    $3, $3, 2
    addi    $4, $4, 1
    bge     $2, $3, loop
output:
    add     $2, $zero, $4
