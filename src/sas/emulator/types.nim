type
  PlugFunction* = proc(iob: var array[256, uint8])
  Cpu* = object
    registers*: array[30, uint32]
    iobus*: array[256, byte]
    plugins*: seq[Plugin]
    memory*: string
  Plugin* = object
    onclock*: PlugFunction
  Instruction32* = object
    opcode*: int
    rd1*: int
    rs1*: uint32
    rs2*: uint32
    imm*: uint32

proc setReg*(cpu: var Cpu, regnum: int, value: uint32) =
  if regnum > 1:
    cpu.registers[regnum] = value

proc getReg*(cpu: Cpu, regnum: int): uint32 =
  if regnum > 1:
    return cpu.registers[regnum]
  elif regnum == 1:
    return 1
  else:
    return 0

proc `[]`*(cpu: Cpu, regnum: int): uint32 {.inline.} =
  getReg(cpu, regnum)