LABLEDDATA:
    .dump "HelloWorld"

strlen:
    mov t1 a0
1:
    ldb t0 a0
    eq t0 zero
    jmp %3f
MYDATA:
    .dump "Hella World in Data"
3:
    jif t0 %2f
    add t1 1
    jmp %1b
    .dump "Unreacheable unlabeld data"
2:
    sub a0 t1
    ret

# Saved in 64 bytes of ram.
