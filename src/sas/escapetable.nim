import std/tables

var esctable* = {
    "\\n": '\n',
    "\\r": '\r',
    "\\a": '\a',
    "\\0": '\0',
    "\\t": '\t',
    "\\'": '\'',
    "\\\"": '"',
    "\\\\": '\\',
    "\\s": ' '
}.toTable