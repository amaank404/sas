# sasi (SAS Interface)  This is base implementation. Others can be loaded in modular fashion.
# Arguments:
var_ioavailable:
    .byte false  # This should be true if IoBus is working correctly. Read it after sasi_init.
.memory sasi_ecalltable 1024  # Allocate 1 kilobyte of memory for Ecall Table

sasi_init:
    # Initialize memory
    set mp %MEMORY_START

    # Test for IOBus
    set t0 0b10101100
    iow zero 0 t0
    ior t1 zero 0
    eq t2 t0 t1
    not t3 t2
    jif t3 %1f

    stb %var_ioavailable t2
1:
    # Initialize Ecall Table
    set ct %sasi_ecall
    
    # Initialize exit ecall
    add t0 mp %sasi_ecalltable
    set t1 %sasi_ecall_exit
    stb t0 8 t1

    ret

# Sasi Ecall handler
sasi_ecall:
    add t0 mp %sasi_ecalltable
    mul t1 a0 word  # Get Index Address from Index
    add t0 t1
    ldw t2 t0  # Load address to function
    call t2  # Call the function
    ret

# Write the exit code at IO[1] and set the IO[1] to true for execution of exit.
sasi_ecall_exit:
    iow zero 1 a1
    set t0 true
    iow zero 2 t0
    ret

mem_clear:
    ret