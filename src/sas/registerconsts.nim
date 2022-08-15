import std/macros
import std/tables

macro genRegConsts(): untyped =
  result = newStmtList()
  var regtable: Table[string, int];
  let zero = quote do:
    const regZero* = 0
  regtable["zero"] = 0
  let one = quote do:
    const regOne* = 1
  regtable["one"] = 1
  let sp = quote do:
    const regSp* = 2
  regtable["sp"] = 2
  let ip = quote do:
    const regIp* = 3
  regtable["ip"] = 3
  let mp = quote do:
    const regMp* = 13
  regtable["mp"] = 13
  let ct = quote do:
    const regCt* = 21
  regtable["ct"] = 21
  result.add zero
  result.add one
  result.add sp
  result.add ip
  result.add mp
  result.add ct
  # `r` series
  for x in 0..27:
    let regident = newIdentNode("regR" & $x)
    let regid = newIntLitNode(x+2)
    let t = quote do:
      const `regident`* = `regid`
    regtable["r" & $x] = regid.intVal.int
    result.add t

  # `g` series
  for x in 0..8:
    let regident = newIdentNode("regG" & $x)
    let regid = newIntLitNode(x+4)
    let t = quote do:
      const `regident`* = `regid`
    regtable["g" & $x] = regid.intVal.int
    result.add t

  # `t` series
  for x in 0..6:
    let regident = newIdentNode("regT" & $x)
    let regid = newIntLitNode(x+14)
    let t = quote do:
      const `regident`* = `regid`
    regtable["t" & $x] = regid.intVal.int
    result.add t
  
  # `a` series
  for x in 0..7:
    let regident = newIdentNode("regA" & $x)
    let regid = newIntLitNode(x+22)
    let t = quote do:
      const `regident`* = `regid`
    regtable["a" & $x] = regid.intVal.int
    result.add t

  var tableconst = nnkTableConstr.newTree()
  for k, v in regtable.pairs():
    tableconst.add nnkExprColonExpr.newTree(newLit(k), newLit(v))

  let t = nnkStmtList.newTree(
    nnkDotExpr.newTree(
      tableconst,
      newIdentNode("toTable")
    )
  )

  result.add t

var registers*: Table[string, int] = genRegConsts()