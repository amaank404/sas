import std/streams
import sas/emulator/emulator

var databytecode: seq[byte]
let alreadydonefp = openFileStream("out.bin", fmRead)
while not alreadydonefp.atEnd:
  databytecode.add alreadydonefp.readChar().byte

databytecode.setLen(databytecode.len + 1024)

var cpu = createCpu(databytecode)
cpu.run()