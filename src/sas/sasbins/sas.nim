import ../toolchain/parser
import ../toolchain/cli

when isMainModule:
  var clioptions: CliOptions = cli.getcliopts()

  if clioptions.action == "compile":
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
  elif clioptions.action == "decompile":
    if clioptions.debugfile.len == 0:
      echo "Debug file required to disassemble, please provide using `--debug=FILENAME`"
    var databytecode = readFile(clioptions.files[0])
    let debuginfo = readFile(clioptions.debugfile).fromTextDebugInfo
    let decompiled = decompile(databytecode, debuginfo)
    writefile(clioptions.output, decompiled)
