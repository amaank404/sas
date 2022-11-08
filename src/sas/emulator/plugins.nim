import std/dynlib
import types

proc loadPlugin*(path: string): Plugin =
  ## Loads the plugin from given file. The provided
  ## file must provide 2 functions:
  ## 
  ## * `proc sasplug_size(): cint`
  ## * `proc sasplug_location(): cint`
  ## * `proc sasplug_onclock(bufferptr: cint, size: cint)`
  let lib = loadLib(path)
  assert lib != nil, "Error loading the dynamic plugin"
  let function = cast[PlugFunction](lib.symAddr("sasplug_onclock"))
  let size = cast[proc(): cint {.stdcall.}](lib.symAddr("sasplug_size"))()
  let location = cast[proc(): cint {.stdcall.}](lib.symAddr("sasplug_location"))()
  return Plugin(location: location, size: size, onclock: function)
