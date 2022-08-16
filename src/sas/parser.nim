import std/strutils
import std/parseutils
import literals
import types
import escapetable
import errors
import private/endians2
import algorithm
import instructions
import regex
import tokens
import registerconsts
import os
import std/tables

## There are many stages to a compiler. One of the first stage
## is parser that converts the hand written human code into
## an intermediate representation with all the pseudo instructions
## expanded. If parser encounters an unknown instruction an error
## is raised.

proc isNumeric(s: string): bool =
  var x: int
  s.parseInt(x) == s.len

proc newDirective*(dir: RegexMatch, text: string): Directive {.inline.} =
  Directive(name: dir.group("name", text)[0], args: dir.group("args", text)[0])

proc newRawInstruction*(ins: string): RawInstruction =
  ## Creates a new RawInstruction object with the given
  ## instruction string. The string must be stripped before
  ## hand and the space between the arguments should be a 
  ## single whitespace character.
  ## 
  ## For example:
  ## 
  ## ```
  ## add ip sp a0
  ## push a0
  ## pop a2
  ## pop 22
  ## set t2 %mylabel
  ## ```
  ## 
  ## this wouldnt work:
  ## 
  ## ```
  ##   add ip sp a0   # A Comment
  ##    ok mp 2
  ## sub a0    a1 10
  ## ```
  let splited = ins.split(' ')
  result.ident = splited[0]
  result.args = splited[1..^1]
  result.signature = result.ident&' '
  for x in result.args:
    if isIntLiteral(x) or isLabelLiteral(x):
      result.signature.add "i "
    elif isRegister(x):
      result.signature.add "r "
    else:
      raise ParseError.newException("Unknown instruction argument: " & x)
  result.signature.setLen(result.signature.len-1)

proc toInstruction*(r: RawInstruction): Instruction =
  result.opcode = realins[r.signature].uint8
  var args: seq[uint32]
  for x in r.args:
    if x.isIntLiteral():
      args.add intLiteral(x).uint32
    elif x.isRegister():
      args.add registers[x].uint32
    else:
      raise ParseError.newException("Unknown literal type for literal: " & x)
  if schemes.hasKey(r.ident):
    case schemes[r.ident]
    of "rr i":
      result.rd1 = args[0].uint8
      result.rs1 = args[1].uint8
      result.imm = args[2]
    of " rri":
      result.rs1 = args[0].uint8
      result.rs2 = args[1].uint8
      result.imm = args[2]
    of "st*":
      result.rs1 = args[0].uint8
      result.imm = args[1]
      result.rs2 = args[2].uint8
    of "rrr":
      result.rd1 = args[0].uint8
      result.rs1 = args[1].uint8
      result.rs2 = args[2].uint8
    of "rr":
      result.rd1 = args[0].uint8
      result.rs1 = args[1].uint8
    else:
      raise ParseError.newException("Unknown conversion scheme: " & schemes[r.ident])
  else: # Default Scheme: rrri
    result.rd1 = args[0].uint8
    result.rs1 = args[1].uint8
    result.rs2 = args[2].uint8
    result.imm = args[3]

proc abs*(v: RawInstruction): seq[RawInstruction] =
  if pseudoins.hasKey(v.signature):
    var insTemplate = pseudoins[v.signature]
    for i, x in v.args:
      insTemplate = insTemplate.replace("$" & $i, x)
    for x in insTemplate.splitLines(false):
      result.add newRawInstruction(x).abs()
  elif realins.hasKey(v.signature):
    result.add v
  else:
    var possibleSignatures: seq[string]
    for x in pseudoins.keys():
      if x.split(' ', 1)[0] == v.ident:
        possibleSignatures.add x
    for x in realins.keys():
      if x.split(' ', 1)[0] == v.ident:
        possibleSignatures.add x
    if possibleSignatures.len == 0:
      raise ParseError.newException("Unknown instruction signature `$1` for instruction `$2` and arguments `$3`. No possible signatures available either." % [v.signature, v.ident, v.args.join(" ")])
    else:
      raise ParseError.newException("Unknown instruction signature `$1` for instruction `$2` and arguments `$3`. Possible signatures for $2 are:\n  $4" % [v.signature, v.ident, v.args.join(" "), possibleSignatures.join("\n  ")])


proc parseAsm*(code: string): seq[Node] =
  ## parse the given code and generate a sequence of nodes.
  var code = code.splitLines(false)
  for i in 0..<code.len:
    code[i] = code[i].replace(comment, "")
    code[i] = code[i].strip()

  var temp = newSeqOfCap[string](code.len)
  for x in code:
    if x.len != 0:
      temp.add x
  code.setLen(temp.len)
  for i, x in temp:
    code[i] = x
  
  # Code has been cleaned of all comments up until here

  # Parse all the lines with regex patterns
  for i, x in code:
    var matches: RegexMatch
    if x.match(directive, matches):
      result.add Node(kind: nkDirective, dirVal: newDirective(matches, x))
    elif x.match(instruction, matches):
      var args = matches.group("args", x)[0].split(' ')
      var argsfinal: string;
      for x in args:
        argsfinal.add ' ' & x.strip()
      result.add Node(kind: nkRawInstruction, rinsVal: newRawInstruction(matches.group("name", x)[0] & argsfinal))
    elif x.match(labelident, matches):
      result.add Node(kind: nkLabel, labelIdent: matches.group("name", x)[0])
    elif x.match(bareinstruction, matches) and not (' ' in x):
      result.add Node(kind: nkRawInstruction, rinsVal: newRawInstruction(matches.group("name", x)[0]))
    else:
      raise ParseError.newException("Unknown type of statement at {$1}: {$2}" % [$i, x])

proc `$`*(tree: seq[Node]): string =
  for x in tree:
    case x.kind:
    of nkRawInstruction:
      result.add "RINS: ins = " & x.rinsVal.ident & ' ' & x.rinsVal.args.join(" ") & "; sig = " & x.rinsVal.signature
    of nkRawData:
      result.add "DATA: len = " & $x.rawVal.data.len
      if x.rawVal.data.len < 100:
        result.add "; data = " & $x.rawVal.data
    of nkDirective:
      result.add "DIR : dir = " & x.dirVal.name & ' ' & x.dirVal.args
    of nkLabel:
      result.add "LABL: idt = " & x.labelident
    of nkInstruction:
      result.add "INS : opcode = 0x" & $x.insVal.opcode.toHex & "; rd1 = " & $x.insVal.rd1 & "; rs1 = " & $x.insVal.rs1 & "; rs2 = " & $x.insVal.rs2 & "; imm = " & $x.insVal.imm
    result.add '\n'

proc resolveIncludeDirectives*(code: seq[Node], libpaths: seq[string] = @[]): seq[Node] =
  ## Resolves all include directives
  for v in code:
    if v.kind == nkDirective:
      var matches: RegexMatch
      if v.dirVal.name == "include":
        if not v.dirVal.args.strip.match(stringliteral, matches):
          raise ParseError.newException("Include directive requires a string argument")
        var stringdata = matches.group("data", v.dirVal.args.strip).join()
        var replacement_tasks: seq[int]
        for i, v in stringdata:
          if v == '\\':
            replacement_tasks.add i
        var done: int
        for x in replacement_tasks:
          stringdata[x - done] = esctable['\\' & string_data[x - done + 1]]
          done += 1
        
        var pfound: bool
        for x in libpaths:
          let p = x / stringdata
          if fileExists(p):
            stringdata = p
            pfound = true
            break
        if not pfound:
          raise ParseError.newException("No library found named {$1} in path: $2" % [stringdata, $libpaths])
        let data = readFile(stringdata)
        result.add resolveIncludeDirectives(parseAsm(data), libpaths)
      else:
        result.add v
    else:
      result.add v

proc compile*(code: sink seq[Node], incdebug: bool): tuple[code: seq[uint8], debuginfo: Table[string, seq[int]]] =
  code.add Node(kind: nkLabel, labelIdent: "MEMORY_START")
  var labellocations: Table[string, seq[int]]
  var labelsetlocations: Table[string, int]
  var mem: int

  var temp: seq[Node]
  # Parse all assembler directives that were left after resolving includes
  for v in code:
    if v.kind == nkDirective:
      case v.dirVal.name
      of "byte":
        temp.add Node(kind: nkRawData, rawVal: RawData(data: @[cast[uint](intLiteral(v.dirVal.args.strip)).uint64.toBytesBE[0]]))
      of "half":
        temp.add Node(kind: nkRawData, rawVal: RawData(data: @(cast[uint](intLiteral(v.dirVal.args.strip)).uint64.toBytesBE[0..1])))
      of "word":
        temp.add Node(kind: nkRawData, rawVal: RawData(data: @(cast[uint](intLiteral(v.dirVal.args.strip)).uint64.toBytesBE[0..3])))
      of "zero":
        let zeros = newSeq[uint8](intLiteral(v.dirVal.args.strip))
        temp.add Node(kind: nkRawData, rawVal: RawData(data: zeros))
      of "nop":
        let noplen = intLiteral(v.dirVal.args.strip)
        let origniallen = temp.len
        temp.setLen(temp.len+noplen)
        for x in 0..<noplen:
          temp[origniallen+x] = Node(kind: nkInstruction, insVal: Instruction(opcode: 1, rd1: 0xff, rs1: 0xff, rs2: 0xff, imm: uint32.high))
      of "memory":
        let splitted = v.dirVal.args.strip.split(space)
        if splitted.len != 2:
          raise ParseError.newException("Expected exactly 2 arguments for memory directive, received: " & $splitted)
        let labelname = splitted[0]
        let literal = intLiteral(splitted[1].strip)
        let location = mem
        mem += literal
        when defined(showWarnings):
          if labelname in labelsetlocations:
            echo "Warning: Duplicate Label " & labelname
        labelsetlocations[labelname] = location
      of "labelset":
        let splitted = v.dirVal.args.strip.split(space)
        if splitted.len != 2:
          raise ParseError.newException("Expected exactly 2 arguments for memory directive, received: " & $splitted)
        let labelname = splitted[0]
        let literal = intLiteral(splitted[1].strip)
        when defined(showWarnings):
          if labelname in labelsetlocations:
            echo "Warning: Duplicate Label " & labelname
        labelsetlocations[labelname] = literal
      of "string", "dump":
        var matches: RegexMatch
        if not v.dirVal.args.strip.match(stringliteral, matches):
          raise ParseError.newException("Unable to parse string argument for string/dump directive: " & v.dirVal.args.strip)
        var stringdata = matches.group("data", v.dirVal.args.strip).join()
        var replacement_tasks: seq[int]
        for i, v in stringdata:
          if v == '\\':
            replacement_tasks.add i
        var done: int
        for x in replacement_tasks:
          stringdata[x - done] = esctable['\\' & string_data[x - done + 1]]
          done += 1
        
        var rawstring = cast[seq[uint8]](stringdata)  # FIXME: Unsafe cast here
        rawstring.add 0'u8  # Null termination of string
        temp.add Node(kind: nkRawData, rawVal: RawData(data: rawstring))
      of "start":
        temp.add Node(kind: nkRawInstruction, rinsVal: newRawInstruction("jmp %" & v.dirVal.args.strip))
      else:
        raise ParseError.newException("Unknown Directive: " & v.dirVal.name)
    else:
      temp.add v
  
  var temp2: seq[Node] = newSeqOfCap[Node](temp.len)

  # Expand Pseudo Instructions
  for v in temp:
    if v.kind == nkRawInstruction:
      let expanded = v.rinsVal.abs()
      for x in expanded:
        temp2.add Node(kind: nkRawInstruction, rinsVal: x)
    else:
      temp2.add v
  
  # At this point, we are done with parsing all instructions
  # and directives to there final form. The instructions are now
  # in a executable form.
  var i: int
  for x in temp2:
    case x.kind
    of nkLabel:
      when defined(showWarnings):
        if labellocations.hasKey(x.labelident) and not x.labelident.isNumeric:
          echo "Warning: Label " & x.labelident & " has been repeated"
      if not labellocations.hasKey(x.labelIdent):
        labellocations[x.labelIdent] = newSeqOfCap[int](1)
      labellocations[x.labelIdent].add i
    of nkRawData:
      i += x.rawVal.data.len
    of nkRawInstruction, nkInstruction:
      i += 8
    of nkDirective:
      raise ParseError.newException("No directives should be found at this stage of compilation. This is a compiler bug and cannot be fixed by user.")

  # All labels have been parsed and now can we can replace
  # label arguments with their absolute values.

  for k, v in labelsetlocations.pairs():
    labellocations[k] = @[v]
  var labellocationsreversed = deepCopy(labellocations)
  for v in labellocationsreversed.mvalues():
    v = v.reversed
  var ci: int
  for index, x in temp2:
    if x.kind == nkRawInstruction:
      for i, v in x.rinsVal.args.mpairs:
        if v.startsWith("%") and not v[1..^2].isNumeric:
          if not labellocations.hasKey(v[1..^1]):
            raise ParseError.newException("No label named " & v[1..^1])
          x.rinsVal.args[i] = $labellocations[v[1..^1]][^1]
        elif v.startsWith("%") and v[1..^2].isNumeric:
          if v.endsWith('b'):
            for x2 in labellocationsreversed[v[1..^2]]:
              if ci >= x2:
                x.rinsVal.args[i] = $x2
          elif v.endsWith('f'):
            for x2 in labellocations[v[1..^2]]:
              if ci < x2:
                x.rinsVal.args[i] = $x2
        elif v.startsWith("%"):
          raise ParseError.newException("Unrecognised Label Type for label $1 at index $2" % [v, $index])
    case x.kind
    of nkRawData:
      if incdebug:
        result.debuginfo['!' & $ci] = @[x.rawVal.data.len]
      ci += x.rawVal.data.len
    of nkRawInstruction, nkInstruction:
      ci += 8
    of nkLabel:
      discard
    else:
      raise ParseError.newException("No other Node types should be found at this stage of compilation. This is a compiler bug and cannot be fixed by user.")
  
  # All the variables have now been resolved. Now we can convert all nodes
  # to there Binary Representation. Here we make an educated guess about
  # the size of output.
  var codefinal = newSeqOfCap[uint8](ci)

  for x in temp2:
    case x.kind
    of nkRawInstruction:
      let r = x.rinsVal.toInstruction
      var final: array[8, uint8]
      final[0] = r.opcode
      final[1] = r.rd1
      final[2] = r.rs1
      final[3] = r.rs2
      final[4..7] = r.imm.toBytesBE
      codefinal.add final
    of nkInstruction:
      let r = x.insVal
      var final: array[8, uint8]
      final[0] = r.opcode
      final[1] = r.rd1
      final[2] = r.rs1
      final[3] = r.rs2
      final[4..7] = r.imm.toBytesBE
      codefinal.add final
    of nkRawData:
      codefinal.add x.rawVal.data
    of nkLabel:
      if incdebug:
        result.debuginfo['@' & x.labelIdent] = labellocations[x.labelIdent].deepCopy
    else:
      raise ParseError.newException("No directives should be found at this stage of compilation. This is a compiler bug and cannot be fixed by user.")

    result.code = codefinal

proc toTextDebugInfo*(debuginfo: Table[string, seq[int]]): string =
  for lbl, locs in debuginfo.pairs():
    result.add "$1:$2\n" % [lbl, locs.join(",")]
  result.setLen(result.len-1)

proc compile*(code: string): seq[uint8] =
  compile(parseAsm(code), false).code

proc compile*(code: sink seq[Node]): seq[uint8] =
  compile(code, false).code