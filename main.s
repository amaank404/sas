# To run this example, compile it and then run the following command
#   sasemu.exe emulate -p stdout -m 1024 out.bin

.start _setup
Mychar:
    .string "This is an example sentence\n"
Helloworld:
    .string "This is another string\n"

print_string:
    set t1 0b10000000
1:
    ldb t0 a0
    eq t2 t0 zero
    jif t2 %2f
    inc a0
    or t0 t0 t1
    iow zero t0 0
    jmp %1b
2:
    ret

_setup:
    set mp %MEMORY_START
    set sp 1024
    jmp %_main

_main:
    set a0 %Mychar
    call %print_string

    set a0 %Helloworld
    call %print_string