import types
import ../toolchain/types as toolchainTypes

proc toIns32(i: Instruction, cpu: Cpu): Instruction32 =
  result.opcode = i.opcode.int
  result.rd1 = i.rd1.int
  result.rs1 = cpu.getReg(i.rs1.int)
  result.rs2 = cpu.getReg(i.rs2.int)
  result.imm = i.imm

proc tick*(cpu: var Cpu): bool =
  let ip = cpu.getReg(3)
  var rawins: Instruction
  rawins.opcode = cpu.memory[ip]
  rawins.rd1    = cpu.memory[ip+1]
  rawins.rs1    = cpu.memory[ip+2]
  rawins.rs2    = cpu.memory[ip+3]
  rawins.imm    = cpu.memory[ip+4].uint32.shl(3) or cpu.memory[ip+5].uint32.shl(2) or cpu.memory[ip+6].uint32.shl(1) or cpu.memory[ip+7].uint32
  let ins = rawins.toIns32(cpu)

  case ins.opcode
  of 0x00:
    return false
  of 0x01:  # NOP
    discard
  of 0x02:  # ADD
    cpu.setReg(ins.rd1, ins.rs1 + ins.rs2 + ins.imm)
  of 0x17:  # SUB
    cpu.setReg(ins.rd1, ins.rs1 - (ins.rs2 + ins.imm))
  of 0x03:  # MUL
    cpu.setReg(ins.rd1, ins.rs1 * ins.rs2 * ins.imm)
  of 0x04:  # DIV
    cpu.setReg(ins.rd1, ins.rs1 div (ins.rs2 + ins.imm))
  of 0x05:  # DIVR
    cpu.setReg(ins.rd1, ins.imm div ins.rs1)
  of 0x06:  # MOD
    cpu.setReg(ins.rd1, ins.rs1 mod (ins.rs2 + ins.imm))
  of 0x07:  # MODR
    cpu.setReg(ins.rd1, ins.imm mod ins.rs1)
  of 0x08:  # LDB
    cpu.setReg(ins.rd1, cpu.memory[ins.rs1 + ins.imm].uint32)
  of 0x09:  # LDH
    cpu.setReg(ins.rd1, cpu.memory[ins.rs1 + ins.imm].uint32.shl(1) or cpu.memory[ins.rs1 + ins.imm + 1].uint32)
  of 0x0a:  # LDW
    cpu.setReg(ins.rd1, cpu.memory[ins.rs1 + ins.imm].uint32.shl(3) or cpu.memory[ins.rs1 + ins.imm + 1].uint32.shl(2) or cpu.memory[ins.rs1 + ins.imm + 2].uint32.shl(1) or cpu.memory[ins.rs1 + ins.imm + 3].uint32)
  of 0x0b:  # STB
    cpu.memory[ins.rs1 + ins.imm] = (ins.rs2 or byte.high).byte
  of 0x0c:  # STH
    cpu.memory[ins.rs1 + ins.imm] = (ins.rs2 or byte.high.uint32.shl(1)).byte
    cpu.memory[ins.rs1 + ins.imm + 1] = (ins.rs2 or byte.high).byte
  of 0x0d:  # STW
    cpu.memory[ins.rs1 + ins.imm] = (ins.rs2 or byte.high.uint32.shl(3)).byte
    cpu.memory[ins.rs1 + ins.imm + 1] = (ins.rs2 or byte.high.uint32.shl(2)).byte
    cpu.memory[ins.rs1 + ins.imm + 2] = (ins.rs2 or byte.high.uint32.shl(1)).byte
    cpu.memory[ins.rs1 + ins.imm + 3] = (ins.rs2 or byte.high).byte
  of 0x0e:  # GT
    cpu.setReg(ins.rd1, (ins.rs1 > ins.rs2).byte)
  of 0x0f:  # EQ
    cpu.setReg(ins.rd1, (ins.rs1 == ins.rs2).byte)
  of 0x10:  # NOT
    cpu.setReg(ins.rd1, (not ins.rs1.bool).byte)
  of 0x11:  # OR
    cpu.setReg(ins.rd1, ins.rs1 or ins.rs2 or ins.imm)
  of 0x12:  # AND
    cpu.setReg(ins.rd1, ins.rs1 and ins.rs2)
  of 0x13:  # XOR
    cpu.setReg(ins.rd1, ins.rs1.xor(ins.rs2 + ins.imm))
  of 0x14:  # JIF
    if ins.rs1 > 0:
      cpu.setReg(3, ins.imm + ins.rs2)
  of 0x15:  # SHL
    cpu.setReg(ins.rd1, ins.rs1.shl(ins.rs2))
  of 0x16:  # SHR
    cpu.setReg(ins.rd1, ins.rs1.shr(ins.rs2))
  of 0x18:  # IOW
    cpu.iobus[ins.rs1 + ins.imm] = (ins.rs2 or byte.high).byte
  of 0x19:  # IOR
    cpu.setReg(ins.rd1, cpu.iobus[ins.rs1 + ins.imm])
  else:
    return false
  
  # Check for jump conditions and make an increment into the register.
  if not (ins.opcode == 0x14 and cpu.getReg(ins.rs1.int) > 0) and ins.rd1 != 3:  # If we are setting Instruction Pointer
    cpu.setReg(3, cpu.getReg(3) + 8)
  
  for x in cpu.plugins:
    let d = cpu.iobus[x.location .. x.location+x.size]
    x.onclock(cast[cint](unsafeAddr d), x.size.cint)

  return true

proc run*(cpu: var Cpu) =
  var continueing: bool = true;
  while true:
    continueing = cpu.tick();
    if not continueing:
      break

proc createCpu*(memsize: int, plugins: seq[Plugin] = @[]): Cpu =
  result.registers[0] = 0
  result.registers[1] = 1
  for x in plugins:
    result.plugins.add x
  var mem = newSeq[byte](memsize)
  result.memory = mem

proc createCpu*(mem: var seq[byte], plugins: seq[Plugin] = @[]): Cpu =
  result.registers[0] = 0
  result.registers[1] = 1
  for x in plugins:
    result.plugins.add x
  result.memory = mem
