import argparse
import std/tables
import plugins
import ../toolchain/version
import types

type
  ShowVersionInfo = object of CatchableError 
  CliOptions* = object
    plugins*: seq[Plugin]
    tracer*: bool
    tracereg*: seq[string]
    memory*: uint32
    action*: string
    file*: string

var parser = newParser:
  help("Sas Emulator provides you with emulation platform for SAS architecture")
  command("emulate"):
    help("Emulate a given source file.")
    option("-p", "--plugin", help="Plugins to enable", multiple=true)
    flag("-t", "--tracer", help="Enable Tracer")
    option("-v", "--tracereg", help="Use with --tracer, Specifies the variables to trace")
    option("-m", "--memory", help="Size of the memory to create that includes the code itself", default=some("1024"))
    arg("file", default=some("out.bin"), help="Binary file to run in the emulator")
  command("list-plugins"):
    help("List all available plugins")

proc getcliopts*(): CliOptions =
  try:
    let opts = parser.parse()
    if opts.command == "version":
      raise ShowVersionInfo.newException("")
    result.action = opts.command
    if opts.command == "emulate":
      for x in opts.emulate.get.plugin:
        if not pluginsTable.hasKey(x):
          raise UsageError.newException("plugin '" & x & "' is not a valid plugin, please check the list of plugins")
        result.plugins.add pluginsTable[x]
      result.tracer = opts.emulate.get.tracer
      result.tracereg.add opts.emulate.get.tracereg
      result.memory = opts.emulate.get.memory.parseUInt.uint32
      result.file = opts.emulate.get.file
    elif opts.command == "list-plugins":
      echo "All available plugins are:"
      for x in pluginsTable.keys:
        echo "\t",x
      quit(1)
  except ShortCircuit as e:
    if e.flag == "argparse_help":
      echo e.help
      quit(1)
  except ShowVersionInfo:
    echo "Sas Compiler v", $SASVERSION
  except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)