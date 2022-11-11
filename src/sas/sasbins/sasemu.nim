import ../emulator/emulator
import ../emulator/cli

when isMainModule:
  var clioptions: CliOptions = cli.getcliopts()

  if clioptions.action == "emulate":
    var databytecode = readFile(clioptions.file)
    databytecode.setLen(clioptions.memory)
    
    var cpu = createCpu(databytecode, clioptions.plugins)
    cpu.run(clioptions.tracer, clioptions.tracereg)
