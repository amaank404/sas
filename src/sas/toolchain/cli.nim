import argparse
import version

type 
  CliOptions* = object
    action*: string
    output*: string
    check*: bool
    debugfile*: string
    files*: seq[string]
    includes*: seq[string]
  ShowVersionInfo = object of CatchableError

var probj* = newParser:
  help("A compiler for sas cpu architecture")
  command "version":
    help("Show version information")
  command "compile":
    help("Compile the given files to a binary")
    option("-o", "--output", help="The file to write the binary to.", default=some("out.bin"))
    flag("-c", "--check", help="Do not save the output, only compile")
    option("-d", "--debug", help="The location to save the debug file, if not provided, no debug file will be generated.", default=some(""))
    option("-i", "--include", help="Include paths to search include files.", multiple=true)
    arg("files", help="The files to compile", nargs = -1)
  command "decompile":
    help("Decompiles a given binary to a single source file")
    option("-d", "--debug", help="The location to read the debug file from", required=true)
    option("-o", "--output", help="The file to write the decompiled sources to, Note: When decompiling, the original file structure is not preserved", some("out.s"))
    arg("file", help="The binary file to decompile", nargs = -1)

proc getcliopts*(): CliOptions=
  try:
    let opts = cli.probj.parse()
    if opts.command == "version":
      raise ShowVersionInfo.newException("")
    result.action = opts.command
    if opts.command == "compile":
      result.output = opts.compile.get.output
      result.files = opts.compile.get.files
      result.check = opts.compile.get.check
      result.debugfile = opts.compile.get.debug
      result.includes = opts.compile.get.include
      if result.files.len == 0:
        raise UsageError.newException("At least one file is required for compilation")
    elif opts.command == "decompile":
      result.output = opts.decompile.get.output
      result.debugfile = opts.decompile.get.debug
      result.files = opts.decompile.get.file
  except ShortCircuit as e:
    if e.flag == "argparse_help":
      echo e.help
      quit(1)
  except ShowVersionInfo:
    echo "Sas Compiler v", $SASVERSION
  except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)