## A test for checking the compilation of add instruction

import strutils
import commons
import ../src/sas/toolchain/parser

let testdata = """
add r1 r2 r3 800
add r1 r2
add r1 r2 r3
add r2 r3 10
jmp 0
set a0 17
mov a0 a1

err
nop
sub a0 a1 a2 0x24
mul a0 a1
mul a0 0b11111111

div a0 10
divr r12 10 r13
mod a0 a1 r1 12
"""

let testresultexpected = """
02 03 04 05 00000320
02 03 03 04 00000000
02 03 04 05 00000000
02 04 05 00 0000000A
02 03 00 00 00000000
02 16 00 00 00000011
02 16 17 00 00000000

00 00 00 00 00000000
01 00 00 00 00000000
17 16 17 18 00000024
03 16 16 17 00000001
03 16 16 01 000000ff

04 16 16 00 0000000a
05 0e 0f 00 0000000a
06 16 17 03 0000000c
""".hexfilt

let testresult = compile(parseAsm(testdata)).toHex

echo testresult
echo testresultexpected

assert testresult == testresultexpected