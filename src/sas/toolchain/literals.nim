import tokens
import registerconsts
import regex
import escapetable
import errors
import constants
import std/strutils
import std/parseutils
import std/tables

proc isIntLiteral*(s: string): bool =
  s.match(hexliteral) or
  s.match(octalliteral) or
  s.match(binaryliteral) or
  s.match(charliteral) or
  s.match(numliteral) or
  s.match(constliteral)

proc isRegister*(s: string): bool {.inline.} =
  registers.hasKey(s)

proc isLabelLiteral*(s: string): bool {.inline.} =
  s.match(label) or s.match(locallabel)

proc intLiteral*(s: string): int =
  var m: RegexMatch
  if s.match(hexliteral, m):
    assert m.group("hex", s)[0].parseHex(result) > 0
    if m.group("sign", s).len > 0:
      if m.group("sign", s)[0] == "-":
        result = -result
  elif s.match(octalliteral, m):
    assert m.group("oct", s)[0].parseOct(result) > 0
    if m.group("sign", s).len > 0:
      if m.group("sign", s)[0] == "-":
        result = -result
  elif s.match(numliteral, m):
    assert m.group("int", s)[0].parseInt(result) > 0
    if m.group("sign", s).len > 0:
      if m.group("sign", s)[0] == "-":
        result = -result
  elif s.match(binaryliteral, m):
    assert m.group("bin", s)[0].parseBin(result) > 0
    if m.group("sign", s).len > 0:
      if m.group("sign", s)[0] == "-":
        result = -result
  elif s.match(charliteral, m):
    var res = m.group("data", s)[0]
    if res.startsWith('\\') and res.len == 2:
      result = esctable[res].int
    else:
      result = res[0].int
  elif s.match(constliteral, m):
    result = consts[s]
  else:
    raise ParseError.newException("Unable to parse integer literal: "&s)