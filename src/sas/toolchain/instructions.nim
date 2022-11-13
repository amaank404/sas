import std/tables
import std/strutils
import std/macros

var pseudoins*: Table[string, string] = static:
  macro defInsSet(t: untyped, statement: static[string]): untyped =
    let s = statement.splitLines(false)
    result = newStmtList()
    for x in s:
      if x.strip() == "" or x.strip().startsWith('#'):
        continue
      let s1 = x.strip().split("=", 1)
      let pseudo = s1[0].strip().newStrLitNode()
      let togen = s1[1].strip().replace('|', '\n').newStrLitNode()
      let temp = quote do:
        `t`[`pseudo`] = `togen`
      result.add temp
  var t = initTable[string, string]()
  t.defInsSet """
  # Write all pseudo instructions below. They are automatically parsed later.
  # Add Pseudo Instructions
    add r r r     = add $0 $1 $2 0
    add r r       = add $0 $0 $1 0
    add r i       = add $0 $0 zero $1
    add r r i     = add $0 $1 zero $2
    mov r r       = add $0 $1 zero 0
    set r i       = add $0 zero zero $1
  
  # Sub Pseudo Instructions
    sub r r r     = sub $0 $1 $2 0
    sub r r       = sub $0 $0 $1 0
    sub r i       = sub $0 $0 zero $1
    sub r r i     = sub $0 $1 zero $2
  
  # Mul Pseudo Instructions
    mul r r r     = mul $0 $1 $2 1
    mul r r       = mul $0 $0 $1 1
    mul r i       = mul $0 $0 one $1
    mul r r i     = mul $0 $1 one $2

  # Div Pseudo Instructions
    div r r r     = div $0 $1 $2 0
    div r r       = div $0 $0 $1 0
    div r i       = div $0 $0 zero $1
    div r r i     = div $0 $1 zero $2

  # Mod Pseudo Instructions
    mod r r r     = mod $0 $1 $2 0
    mod r r       = mod $0 $0 $1 0
    mod r i       = mod $0 $0 zero $1
    mod r r i     = mod $0 $1 zero $2
  
  # Ldb Pseudo Instructions
    ldb r r       = ldb $0 $1 0
    ldb r i       = ldb $0 zero $1
  # Ldh Psudo Instructions
    ldh r r       = ldh $0 $1 0
    ldh r i       = ldh $0 zero $1
  # Ldw Pseudo Instructions
    ldw r r       = ldw $0 $1 0
    ldw r i       = ldw $0 zero $1

  # Jmp Pseudo Instructions
    jmp r i       = add ip zero $0 $1
    jmp r         = add ip zero $0 0
    jmp i         = add ip zero zero $0
  
  # Stb Pseudo Instructions
    stb r r       = stb $0 $1 0
    stb r i       = stb zero $0 $1

  # Sth Pseudo Instructions
    sth r r       = sth $0 $1 0
    sth r i       = sth zero $0 $1

  # Stw Pseudo Instructions
    stw r r       = stw $0 $1 0
    stw r i       = stw zero $0 $1

  # Complex Pseudo Instructions
    push r        = sub sp 4|stw sp $0
    pop r         = ldw $0 sp|add sp 4
    call i        = add t0 ip 32|sub sp 4|stw sp t0|set ip $0
    call r        = add t0 ip 32|sub sp 4|stw sp t0|set ip $0
    ret           = ldw t0 sp|add sp 4|mov ip t0
    ecall         = add t0 ip 32|sub sp 4|stw sp t0|mov ip ct
  
  # Boolean Based Instructions
    gt r r        = gt $0 $0 $1
    lt r r r      = gt $0 $2 $1
    lt r r        = gt $0 $1 $0
    eq r r        = eq $0 $0 $1
    not r         = not $0 $0 
    neq r r r     = eq $0 $1 $2|not $0 $0
    neq r r       = eq $0 $0 $1|not $0 $0
    or r r r      = or $0 $1 $2 0
    or r r        = or $0 $0 $1 0
    or r r i      = or $0 $1 zero $2
    or r i        = or $0 zero zero $1
    and r r       = and $0 $0 $1
    xor r r r     = xor $0 $1 $2 0
    xor r r i     = xor $0 $1 zero $2
    xor r r       = xor $0 $0 $1 0
    xor r i       = xor $0 $0 zero $1
  
  # Jump if true Instructions
    jif r i       = jif $0 zero $1
    jif r r       = jif $0 $1 0
  
  # Bit Shift Instructions
    shl r r r     = shl $0 $1 $2 0
    shl r r       = shl $0 $0 $1 0
    shl r i       = shl $0 $0 zero $1
    
    shr r r r     = shr $0 $1 $2 0
    shr r r       = shr $0 $0 $1 0
    shr r i       = shr $0 $0 zero $1

  # Increment / Decrement instructions
    inc r         = add $0 $0 zero 1
    dec r         = sub $0 $0 zero 1

  # Logical Pseudo Instructions
    lnot r        = eq $0 $0 zero
    lnot r r      = eq $0 $1 zero
    lnm r         = and $0 1
    lnm r r       = and $0 $1 1
  """
  t

let realins* = {
  "err": 0x00,
  "nop": 0x01,
  "add r r r i": 0x02,
  "sub r r r i": 0x17,
  "mul r r r i": 0x03,
  "div r r r i": 0x04,
  "divr r r i": 0x05,
  "mod r r r i": 0x06,
  "modr r r i": 0x07,
  "ldb r r i": 0x08,
  "ldh r r i": 0x09,
  "ldw r r i": 0x0a,
  "stb r r i": 0x0b,
  "sth r r i": 0x0c,
  "stw r r i": 0x0d,
  "gt r r r": 0x0e,
  "eq r r r": 0x0f,
  "not r r": 0x10,
  "or r r r i": 0x11,
  "and r r r": 0x12,
  "xor r r r i": 0x13,
  "jif r r i": 0x14,
  "shl r r r i": 0x15,
  "shr r r r i": 0x16,
  "iow r r i": 0x18,
  "ior r r i": 0x19
}.toTable

var realinsOpposite*: Table[int, string]
for k, v in realins.pairs:
  realinsOpposite[v] = k

let schemes* = {
  "err": "",
  "nop": "",
  "divr": "rr i",
  "modr": "rr i",
  "ldb": "rr i",
  "ldh": "rr i",
  "ldw": "rr i",
  "stb": " rri",
  "sth": " rri",
  "stw": " rri",
  "jif": " rri",
  "iow": " rri",
  "ior": "rr i",
  "gt": "rrr",
  "eq": "rrr",
  "not": "rr",
  "and": "rrr",
}.toTable