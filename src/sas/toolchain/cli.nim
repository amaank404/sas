import std/parseopt
import std/os
import version

var helpstring = """
SAS, Simple and Small architecture assembler. This assembler provides you
with a compiler, decompiler, parser and repl for converting to and from
binary instructions.

Usage:
  sas (c | compile) [-ocdi] [--] <filename>...
  sas (d | decompile) [-d] [--] <binaryfile>

Options:
  -h --help             Show this help message.
  -v --version          Show version information.
  -o FILE --out=FILE    When compiling, this is the file that shall store
                        the binary output.
                        When decompiling, this is the file that shall contain
                        the decompiled source code.


Compiler Options:
  -c --check            Do not save the output, instead just see if it compiles.

  -d DBGFILE --debug=DBGFIle
                        The location to save the debuging output if the program
                        needs to be debuged or disassembled later.
                        If decompiling, the location of the debug file.
  -i PATH --include PATH    Specify an include path that shall be added in the library path.

Decompiler Options:
  Note The decompiler when used upon a binary will only generate
        a huge source file with no distinctions of original files it
        was compiled from.
"""

var p = initOptParser(commandLineParams(),
  shortNoVal = {'c'},
  longNoVal = @["check"]
)

type CliOptions* = object
  action*: string
  output*: string
  check*: bool
  debugfile*: string
  files*: seq[string]
  includes*: seq[string]

var clioptions*: CliOptions
# Setting the defaults
clioptions.output = "sasoutput"

while true:
  p.next()
  case p.kind
  of cmdEnd:
    break
  of cmdShortOption, cmdLongOption:
    case p.key
    of "o", "out":
      clioptions.output = p.val
    of "d", "debug":
      clioptions.debugfile = p.val
    of "c", "check":
      clioptions.check = true
    of "i", "include":
      clioptions.includes.add p.val
    of "h", "help":
      echo helpstring
      quit(0)
    of "v", "version":
      echo "SAS v", SASVERSION, " supports minimum v", MINSASVERSION
  of cmdArgument:
    if clioptions.action.len == 0:
      clioptions.action = p.key
    else:
      case clioptions.action
      of "compile", "c":
        clioptions.files.add p.key
      of "decompile", "d":
        if clioptions.files.len != 0:
          echo "decompilation expects only one positional argument. Multiple provided"
          quit(1)
        clioptions.files.add p.key
      else:
        echo "No positional arguments were expected for `" & clioptions.action & '`'