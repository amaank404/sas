# Sas (Simple and Small) v1

A Very simple cpu architecture. Simpler than Risc-V atleast and
limited to 32-bit. It consist of only 25 instructions total and all
others are just pseudo instructions to cleverly use other instructions.
A bootloader of 512 bytes should be able to store 64 instructions. 64 is
less but enough for first stage of a bootloader. 1 MB of storage can
contain 131072 instructions. At the same time Riscv can store double or
even triple the instructions but the instructions from riscv can not do
a lot in a single call. But how does it implement so many complex things
in only 25 instructions? Well, it uses a lot of pseudo instructions that
evaluate to some other instruction at compile time. Some of these instructions
can have multi instruction output. There are more pseudo instructions
than there are actual instructions.

## Registers

All registers are signed and all arithmetic operations
are also signed. Default value for Instruction Pointer is 0.
Thus the first instructions executed are executed from memory
address 0, This can be hardwired to ROM for the computer
| Reg ID | Register | Conventional Name | Use | Saver |
| --- | --- | --- | --- | --- |
| 0 | zero | zero | 0 | Constant |
| 1 | one | one | 1 | Constant |
| 2 | r0 | sp | Stack Pointer | Callee |
| 3 | r1 | ip | Instruction Pointer | Caller |
| 4 | r2 | g0 | General Purpose Register | Callee |
| 5 | r3 | g1 | General Purpose Register | Callee |
| 6 | r4 | g2 | General Purpose Register | Callee |
| 7 | r5 | g3 | General Purpose Register | Callee |
| 8 | r6 | g4 | General Purpose Register | Callee |
| 9 | r7 | g5 | General Purpose Register | Callee |
| 10 | r8 | g6 | General Purpose Register | Callee |
| 11 | r9 | g7 | General Purpose Register | Callee |
| 12 | r10 | g8 | General Purpose Register | Callee |
| 13 | r11 | mp | Memory Pointer | Callee |
| 14 | r12 | t0 | Temprorary Register | Caller |
| 15 | r13 | t1 | Temprorary Register | Caller |
| 16 | r14 | t2 | Temprorary Register | Caller |
| 17 | r15 | t3 | Temprorary Register | Caller |
| 18 | r16 | t4 | Temprorary Register | Caller |
| 19 | r17 | t5 | Temprorary Register | Caller |
| 20 | r18 | t6 | Temprorary Register | Caller |
| 21 | r19 | ct | Call Table Function | Callee |
| 22 | r20 | a0 | Argument Register | Caller |
| 23 | r21 | a1 | Argument Register | Caller |
| 24 | r22 | a2 | Argument Register | Caller |
| 25 | r23 | a3 | Argument Register | Caller |
| 26 | r24 | a4 | Argument Register | Caller |
| 27 | r25 | a5 | Argument Register | Caller |
| 28 | r26 | a6 | Argument Register | Caller |
| 29 | r27 | a7 | Argument Register | Caller |

## Instruction Pointer Behaviour
Instruction Pointer is incremented at the end of clock when
the execution of the instruction loaded has been complete.

## IOBus
Size for IOBus is 256 bytes because the IOBus address is
implemented with 8-bits.

## Instructions

This is the instruction set. A lot of them are just pseudo instructions
that use the other instruction in a smart way. Assemblers for this
languages are supposed to implement all instructions and pseudo instructions
to be called "compilant with sas specs".

| OpCode | Identifier | arg1 | arg2 | arg3 | arg4 | Description | Asm Syntax |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0x00 | err | - | - | - | - | Exit program immidiately (erronous way) | err |
| 0x01 | nop | - | - | - | - | No Operation | nop |
| 0x02 | add | rd1 | rs1 | rs2 | imm | rd1 = rs1+rs2+imm | add dest source1 source2 literal |
| pseudo | add | rd1 | rs1 | rs2 | - | rd1 = rs1+rs2 | add dest source1 source2 |
| pseudo | add | rd1 | rs1 | - | - | rd1 += rs1 | add dest source |
| pseudo | add | rd1 | - | - | imm | rd1 += imm | add dest literal |
| pseudo | add | rd1 | rs1 | - | imm | rd1 = rs1+imm | add dest source literal |
| pseudo | mov | rd1 | rs1 | - | - | rd1 = rs1 | mov dest source |
| pseudo | set | rd1 | - | - | imm | rd1 = imm | set dest literal |
| 0x17 | sub | rd1 | rs1 | rs2 | imm | rd1 = rs1-(rs2+imm) | sub dest source1 source2 literal |
| pseudo | sub | rd1 | rs1 | rs2 | - | rd1 = rs1-rs2 | sub dest source1 source2 |
| pseudo | sub | rd1 | rs1 | - | - | rd1 -= rs1 | sub dest source |
| pseudo | sub | rd1 | - | - | imm | rd1 -= imm |sub dest literal |
| pseudo | sub | rd1 | rs1 | - | imm | rd1 = rs1-imm | sub dest source literal |
| 0x03 | mul | rd1 | rs1 | rs2 | imm | rd1 = rs1\*rs2\*imm | mul dest source1 source2 literal |
| pseudo | mul | rd1 | rs1 | rs2 | - | rd1 = rs1\*rs2 | mul dest source1 source2 |
| pseudo | mul | rd1 | rs1 | - | - | rd1 \*= rs1 | mul dest source |
| pseudo | mul | rd1 | - | - | imm | rd1 \*= imm | mul dest literal |
| pseudo | mul | rd1 | rs1 | - | imm | rd1 = rs1\*imm | mul dest source literal |
| 0x04 | div | rd1 | rs1 | rs2 | imm | rd1 = rs1/(rs2+imm) | div dest source1 source2 literal |
| pseudo | div | rd1 | rs1 | rs2 | - | rd1 = rs1/rs2 | div dest source1 source2 |
| pseudo | div | rd1 | rs1 | - | - | rd1 /= rs1 | div dest source |
| pseudo | div | rd1 | - | - | imm | rd1 /= imm | div dest literal |
| pseudo | div | rd1 | rs1 | - | imm | rd1 = rs1/imm | div dest source literal |
| 0x05 | divr | rd1 | rs1 | - | imm | rd1 = imm/rs1 | divr dest source literal  |
| 0x06 | mod | rd1 | rs1 | rs2 | imm | rs1 = rs1%(rs2+imm) | mod dest source1 source2 literal |
| pseudo | mod | rd1 | rs1 | rs2 | - | rd1 = rs1%rs2 | mod dest source1 source2 |
| pseudo | mod | rd1 | rs1 | - | - | rd1 %= rs1 | mod dest source |
| pseudo | mod | rd1 | - | - | imm | rd1 %= imm | mod dest literal |
| pseudo | mod | rd1 | rs1 | - | imm | rd1 = rs1%imm | mod dest source literal |
| 0x07 | modr | rd1 | rs1 | - | imm | rd1 = imm%rs1 | modr dest source literal |
| 0x08 | ldb | rd1 | rs1 | - | imm | rd1 = mem\[rs1+imm\](1byte) | ldb dest source literal |
| pseudo | ldb | rd1 | rs1 | - | - | rd1 = mem\[rs1\](1byte) | ldb dest source |
| pseudo | ldb | rd1 | - | - | imm | rd1 = mem\[imm\](1byte) | ldb dest literal |
| 0x09 | ldh | rd1 | rs1 | - | imm | rd1 = mem\[rs1+imm\](2byte) | ldh dest source literal |
| pseudo | ldh | rd1 | rs1 | - | - | rd1 = mem\[rs1\](2byte) | ldh dest source |
| pseudo | ldh | rd1 | - | - | imm | rd1 = mem\[imm\](2byte) | ldh dest literal |
| 0x0a | ldw | rd1 | rs1 | - | imm | rd1 = mem\[rs1+imm\](4byte) | ldw dest source literal |
| pseudo | ldw | rd1 | rs1 | - | - | rd1 = mem\[rs1\](4byte) | ldw dest source |
| pseudo | ldw | rd1 | - | - | imm | rd1 = mem\[imm\](4byte) | ldw dest literal |
| pseudo | jmp | - | rs1 | - | imm | ip = rs1 + imm | jmp source literal |
| pseudo | jmp | - | rs1 | - | - | ip = rs1 | jmp source |
| pseudo | jmp | - | - | - | imm | ip = imm | jmp literal |
| 0x0b | stb | - | rs1 | rs2 | imm | mem\[rs1+imm\](1byte) = rs2 | stb dest source literal |
| pseudo | stb | - | rs1 | rs2 | - | mem\[rs1\](1byte) = rs2 | stb dest source |
| pseudo | stb | - | - | rs2 | imm | mem\[imm\](1byte) = rs2 | stb source literal |
| 0x0c | sth | - | rs1 | rs2 | imm | mem\[rs1+imm\](2byte) = rs2 | sth dest source literal |
| pseudo | sth | - | rs1 | rs2 | - | mem\[rs1\](2byte) = rs2 | sth dest source |
| pseudo | sth | - | - | rs2 | imm | mem\[imm\](2byte) = rs2 | sth source literal |
| 0x0d | stw | - | rs1 | rs2 | imm | mem\[rs1+imm\](4byte) = rs2 | stw dest source literal |
| pseudo | stw | - | rs1 | rs2 | - | mem\[rs1\](4byte) = rs2 | stw dest source |
| pseudo | stw | - | - | rs2 | imm | mem\[imm\](4byte) = rs2 | stw source literal |
| pseudo | push | - | rs1 | - | - | sub sp 4 <br/> stw sp {rs1} | push source |
| pseudo | pop | rd1 | - | - | - | ldw {rd1} sp <br/> add sp 4 | pop dest |
| pseudo | call | - | - | - | imm | add t0 ip zero 32 <br/> push t0 <br/> set ip {imm} | call literal |
| pseudo | call | - | rs1 | - | - | add t0 ip zero 32 <br/> push t0 <br/> mov ip {rs1} | call source |
| pseudo | ret | - | - | - | - | ldw t0 sp <br/> add sp 4 <br/> mov ip t0 | ret |
| pseudo | ecall | - | - | - | - | call ct | ecall |
| 0x0e | gt | rd1 | rs1 | rs2 | - | rd1 = rs1 \> rs2 | gt dest source1 source2 |
| pseudo | gt | rd1 | rs1 | - | - | rd1 = rd1 \> rs1 | gt dest source |
| pseudo | lt | rd1 | rs1 | rs2 | - | rd1 = rs1 < rs2 | lt dest source1 source2 |
| pseudo | lt | rd1 | rs1 | - | - | rd1 = rd1 < rs2 | lt dest source |
| 0x0f | eq | rd1 | rs1 | rs2 | - | rd1 = rs1 == rs2 | eq dest source1 source2 |
| pseudo | eq | rd1 | rs1 | - | - | rd1 = rd1 == rs1 | eq dest source |
| 0x10 | not | rd1 | rs1 | - | - | rd1 = !rs1 (bitflip) | not dest source |
| pseudo | not | rd1 | - | - | - | rd1 = !rd1 (bitflip)| not dest |
| pseudo | neq | rd1 | rs1 | rs2 | - | eq {rd1} {rs1} {rs2} <br/> not {rd1} | neq dest source1 source2 |
| pseudo | neq | rd1 | rs1 | - | - | eq {rd1} {rd1} {rs1} <br/> not {rd1} | neq dest source |
| 0x11 | or | rd1 | rs1 | rs2 | imm | rd1 = rs1 \| rs2 \| imm | or dest source1 source2 literal |
| pseudo | or | rd1 | rs1 | rs2 | - | rd1 = rs1 \| rs2 | or dest source1 source2 |
| pseudo | or | rd1 | rs1 | - | - | rd1 \|= rs1 | or dest source |
| pseudo | or | rd1 | rs1 | - | imm | rd1 = rs1 \| imm | or dest source literal |
| pseudo | or | rd1 | - | - | imm | rd1 \|= imm | or dest literal |
| 0x12 | and | rd1 | rs1 | rs2 | - | rd1 = rs1 & rs2 | and dest source1 source2 |
| pseudo | and | rd1 | rs1 | - | - | rd1 &= rs1 | and dest source |
| 0x13 | xor | rd1 | rs1 | rs2 | imm | rd1 = rs1 ^ (rs2 + imm) | xor dest source1 source2 literal |
| pseudo | xor | rd1 | rs1 | rs2 | - | rd1 = rs1 ^ rs2 | xor dest source1 source2 |
| pseudo | xor | rd1 | rs1 | - | imm | rd1 = rs1 ^ imm | xor dest source literal |
| pseudo | xor | rd1 | rs1 | - | - | rd1 ^= rs1 | xor dest source |
| pseudo | xor | rd1 | - | - | imm | rd1 ^= imm | xor dest literal |
| 0x14 | jif | - | rs1 | rs2 | imm | if {rs1}==true: jmp {imm}+{rs2} | jif source1 source2 literal |
| pseudo | jif | - | rs1 | - | imm | if {rs1}==true: jmp {imm} | jif source literal |
| pseudo | jif | - | rs1 | rs2 | - | if {rs1}==true: jmp {rs2} | jif source1 source2 |
| 0x15 | shl | rd1 | rs1 | rs2 | imm | rd1 = rs1 << (rs2 + imm) | shl dest source1 source2 literal |
| pseudo | shl | rd1 | rs1 | rs2 | - | rd1 = rs1 << rs2 | shl dest source1 source2 |
| pseudo | shl | rd1 | rs1 | - | - | rd1 <<= rs1 | shl dest source |
| pseudo | shl | rd1 | - | - | imm | rd1 <<= imm | shl dest literal |
| 0x16 | shr | rd1 | rs1 | rs2 | imm | rd1 = rs1 \>\> (rs2 + imm) | shr dest source1 source2 literal |
| pseudo | shr | rd1 | rs1 | rs2 | - | rd1 = rs1 \>\> rs2 | shr dest source1 source2 |
| pseudo | shr | rd1 | rs1 | - | - | rd1 \>\>= rs1 | shr dest source |
| pseudo | shr | rd1 | - | - | imm | rd1 \>\>= imm | shr dest literal |
| 0x18 | iow | - | rs1 | rs2 | imm | iobus[rs1+imm] = rs2 | iow source1 source2 literal |
| 0x19 | ior | rd1 | rs1 | - | imm | rd1 = iobus[rs1+imm] | ior dest source literal |
| pseudo | inc | rd1 | - | - | - | rd1 += 1 | inc dest |
| pseudo | dec | rd1 | - | - | - | rd1 -= 1 | dec dest |
| pseudo | lnot | rd1 | - | - | - | rd1 = !rd1 (logical) | lnot dest |
| pseudo | lnot | rd1 | rs1 | - | - | rd1 = !rs1 (logical) | lnot dest source1 |
| pseudo | lnm | rd1 | - | - | - | rd1 = rd1 & 1 | lnm dest |
| pseudo | lnm | rd1 | rs1 | - | - | rd1 = rs1 & 1 | lnm dest source1 | 

## Instruction Format
Instructions are fixed length and size is 8 bytes. There format
is as follows. They are also in Big Endian order. The whole system
is in Big Endian Order.

`[opcode:1byte] [arg1:1byte] [arg2:1byte] [arg3:1byte] [arg4:4byte]`

## Assembly
Assembly language can have the following types of lines:

* Directives:  `.text`
* Instruction: `add g0 g0 zero 102`
* Labels: `labelname:`
* Local Labels: `{number}:`
* Comments: `{statement}  #Comment`

Literal Arguments to an instruction can be provided as follows

* `0x{hexnumber}`
* `0o{octalnumber}`
* `0b{binary}`
* `{number}`
* `'{character}'`
* `word` = 4
* `half` = 2
* `byte` = 1
* `true` = 1
* `false` = 0
* `%label`
* `%{locallabel}f` Local Label forward
* `%{locallabel}b` Local Label backwards


### `.byte {literal}`
Adds a byte literal.

### `.zero {literal}`
Add given number of zeroed bytes.

### `.string "{rawdata}"`
Add a string there terminated with null

### `.dump "{rawdata}"`
Add data as whole without any suffix.

### `.nop {literal}`
Add given number of `NOP` instructions

### `.half {literal}`
Add a 16-bit number here

### `.word {literal}`
Add a 32-bit number here

### `.memory {label} {size}`
a pointer to space in memory relative to register `mp`. The given space
is of given size and can be accesed through provided label. It would
be used in a program like the following:

```asm
.start _main
.memory mynumber 1  # Allocate 1 byte of memory to mynumber

_main:
    # Initialize memory
    set mp %MEMORY_START

    set t0 1
    stb mp %mynumber t0  # Store t0 at address of mynumber.
```

A label named `MEMORY_START` is automatically appended by assembler and
marks the end of program and first address of memory start.

### `.include "{filepath}"`
Include another assembly file here. It does not prevent duplicates so be aware!

### `.start {label}`
Add a jump instruction to label. Usually this is kept at begginning
of assembly file, above all directives. It is equivalent to `jmp %{label}`.

### `.labelset {label} {value}`
Makes sure that the label is set to the given value regardless
of labels present within the code. Incase of duplicate labelset
directives, the last directive will be considered.

## Examples

A counter that counts from 0 to 10 without any external libraries
```asm
.start _main

_main:
    set t0 0         # Counter
    set t1 10        # Maximum
    set t2 false     # Condition

1:
    add t0 1         # Increment t0
    eq t2 t1 t0      # If counter is at 10
    jif t2 %2f       # Then jump forward to local label 2
    jmp %1b          # Continue the loop
2:
    err              # Exit out
```

Hello World with sasi frameworks:

```asm
.start _main
# Include Interface Libraries
.include "lib/sasi/sasi.s"
.include "lib/sasi/sasi-text.s"

helloworld:
    .string "Hello, World!"
exitdidnotwork:
    .string "Exit did not work! Trapping in a loop!"

_main:
    # Initialize Sasi
    call %sasi_init  # Sets up a ecall handler for us.
    call %sasi_text_init  # Adds text related ecall handler

    # Print hello world using sasi syscalls
    set a0 1  # Call: PrintConsole
    set a1 %helloworld
    ecall

    # Exit with code 0
    set a0 2  # Call: exit
    set a1 0  # ExitCode: 0
    ecall

    # If it did not exit somehow. Trap it in a loop
    set a0 1  # Call: PrintConsole
    set a1 %exitdidnotwork
    ecall

1:
    jmp 1b
```

## Function Calling Convention

All arguments are passed through Argument registers which are not guarenteed to be same as before call and returned through Argument registers. If the arguments do not fit in the argument registers, overflowing arguments are pushed to stack.