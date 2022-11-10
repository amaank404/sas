# Uncompiles SAS bytecode by using provided dbg info files
import std/tables
import std/strutils
import instructions
import types
import errors

# proc cmpnode(a, b: tuple[A: int, B: Node]): int =  # Sorts by looking at the key.
#   if a.A > b.A:
#     result = 1
#   elif a.A < b.A:
#     result = -1
#   else:
#     if a.B.kind == nkLabel and b.B.kind == nkLabel:
#       result = 0
#     elif a.B.kind == nkLabel and b.B.kind != nkLabel:
#       result = 1
#     else:
#       result = -1

proc toregstr(i: uint8): string =
  if i > 1:
    return 'r' & $(i-2)
  elif i == 1:
    return "one"
  else:
    return "zero"

proc decompile*(bytecode: string, debuginfo: Table[string, seq[int]]): string =
  var 
    ins: Instruction
    i: int
  var
    labels: Table[int, seq[string]]
    skips: Table[int, int]
  for k, v in debuginfo.pairs():
    if k.startsWith("@"):  # Label
      for x in v:
        discard labels.hasKeyOrPut(x, newSeq[string](1))
        labels[x][0] = k[1..^1]
    elif k.startsWith("!"):  # Data Dump
      skips[k[1..^1].parseInt] = v[0]

  var final: string

  while i < bytecode.len:
    if labels.hasKey(i):
      for x in labels[i]:
        final.add(x & ":\n")
    if skips.hasKey(i):
      # There is a skip with some data contained
      var skipdata = newStringOfCap(skips[i])
      for x in 0..<skipdata.len:
        skipdata.add bytecode[i+x]
      if skipdata[^1] == '\0':
        final.add(".string \"")
        skipdata.removeSuffix('\0')
      else:
        final.add(".dump \"")
      # final.setLen(final.len + skipdata.len)  # Pre Allocate enough space
      for x in skipdata:
        let chrx = x.char
        if chrx == '\n':
          final.add "\\n"
        elif chrx == '"':
          final.add "\\\""
        else:
          final.add chrx
      final.add "\"\n"
      i += skips[i]
      continue
    ins.opcode = bytecode[i].uint8
    ins.rd1    = bytecode[i+1].uint8
    ins.rs1    = bytecode[i+2].uint8
    ins.rs2    = bytecode[i+3].uint8
    ins.imm    = bytecode[i+4].uint32.shl(3) or bytecode[i+5].uint32.shl(2) or bytecode[i+6].uint32.shl(1) or bytecode[i+7].uint32
    # At this stage we have the skips and labels figured out, We also have
    # the raw instruction and we now only need to convert the raw instruction
    # to a string representation by using their signatures etc.

    # First, we would like its name by using opcode table
    let signature = realinsOpposite[ins.opcode.int]
    let name = signature.split(' ', 1)[0]

    # Now we do have the name, to reverse engineer it. We would use its instruction
    # scheme.
    let scheme = schemes.getOrDefault(name, "rrri")
    var instructionstr: string = name & ' '

    case scheme
    of "rr i":
      instructionstr.add "$1 $2 $3" % [ins.rd1.toregstr, ins.rs1.toregstr, $ins.imm]
    of " rri":
      instructionstr.add "$1 $2 $3" % [ins.rs1.toregstr, ins.rs2.toregstr, $ins.imm]
    of "rrr":
      instructionstr.add "$1 $2 $3" % [ins.rd1.toregstr, ins.rs1.toregstr, ins.rs2.toregstr]
    of "rr":
      instructionstr.add ins.rd1.toregstr & ' ' & ins.rs1.toregstr
    of "rrri":
      instructionstr.add "$1 $2 $3 $4" % [ins.rd1.toregstr, ins.rs1.toregstr, ins.rs2.toregstr, $ins.imm]
    of "":
      discard  # No need to append any thing
    else:
      raise ParseError.newException("Error unknown instruction scheme: " & scheme)

    final.add "    " & instructionstr & '\n'
    i += 8
  return final