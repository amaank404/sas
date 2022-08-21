import sas/toolchain/parser
import sas/toolchain/types
import std/strutils
import std/streams
import sas/toolchain/cli

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
  # signatureRepl(true)
  if clioptions.action == "c" or clioptions.action == "compile":
    var srccode: string
    for x in clioptions.files:
      srccode.add '\n'
      srccode.add readFile(x)
    clioptions.includes.add "."
    let asmparsed = parseAsm(srccode)
    let includeresolved = resolveIncludeDirectives(asmparsed, clioptions.includes)
    if not clioptions.check:
      let compiled = compile(includeresolved, clioptions.debugfile.len > 0)
      writeFile(clioptions.output, compiled.code)
      if clioptions.debugfile.len > 0:
        writeFile(clioptions.debugfile, compiled.debuginfo.toTextDebugInfo)
    else:
      try:
        discard compile(includeresolved)
      except:
        echo "Does not compile"
        echo getCurrentExceptionMsg()
  elif clioptions.action == "d" or clioptions.action == "decompile":
    if clioptions.debugfile.len == 0:
      echo "Debug file required to disassemble, please provide using `--debug=FILENAME`"
    var databytecode: seq[byte]
    let alreadydonefp = openFileStream(clioptions.files[0], fmRead)
    while not alreadydonefp.atEnd:
      databytecode.add alreadydonefp.readChar().byte

    let debuginfo = readFile(clioptions.debugfile).fromTextDebugInfo
    let decompiled = decompile(databytecode, debuginfo)
    writefile(clioptions.output, decompiled)
  else:
    echo "Unrecognized action: `$1`" % [clioptions.action]
