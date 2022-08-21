import std/tables
import std/strutils

proc toTextDebugInfo*(debuginfo: Table[string, seq[int]]): string =
  for lbl, locs in debuginfo.pairs():
    result.add "$1:$2\n" % [lbl, locs.join(",")]
  result.setLen(result.len-1)

proc fromTextDebugInfo*(debuginfo: string): Table[string, seq[int]] =
  for line in debuginfo.splitLines(false):
    let t = line.split(":", 1)
    let first = t[0]
    let vals = t[1]
    let valsseq = vals.split(",")
    var intvals = newSeqOfCap[int](valsseq.len)
    for x in valsseq:
      intvals.add x.parseInt
    result[first] = intvals
