import types
import std/tables
import plugins/stdout

let pluginsTable*: Table[string, Plugin] = {
  "stdout": stdout.stdoutPlugin
}.toTable