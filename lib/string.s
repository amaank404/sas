strlen:
    mov t1 a0
1:
    ldb t0 a0
    eq t0 zero
    jif t0 %2f
    add t1 1
    jmp %1b
2:
    sub a0 t1
    ret

# Saved in 64 bytes of ram.
