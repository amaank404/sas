import ../emulator/emulator
import ../emulator/plugins/stdout

var databytecode = readFile("out.bin")
databytecode.setLen(databytecode.len + 1024)

var cpu = createCpu(databytecode)
cpu.plugins.add(stdoutPlugin)
cpu.run()
