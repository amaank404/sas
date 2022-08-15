import sas/parser
import sas/types
import std/strutils

proc signatureRepl*(expandPseudo: bool = false) =
  ## An interactive repl that is used for development
  ## run it to parse instruction signatures.
  while true:
    stdout.write(">")
    stdout.flushFile()
    var inp: string
    if not stdin.readLine(inp):
      echo "Quitting"
      break
    inp = inp.strip()
    try:
      var ins = newRawInstruction(inp)
      if expandPseudo:
        echo "Original:"
        echo "  ", ins
        echo "Expanded:"
        for x in ins.abs:
          echo "  ", x
      else:
        echo ins
    except Exception:
      echo "Error Encountered: ", getCurrentExceptionMsg()

when isMainModule:
  #signatureRepl(true)
  let srccode = readFile("test.s")
  let asmparsed = parseAsm(srccode)
  let includeresolved = resolveIncludeDirectives(asmparsed, @["lib", "."])
  let compiled = compile(includeresolved)
  #echo compiled
  writeFile("out.bin", compiled)