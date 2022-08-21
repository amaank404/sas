const 
  SASVERSION* = (major: 1, minor: 0, patch: 0)
  MINSASVERSION* = (major: 1, minor: 0, patch: 0)

proc `$`*(v: tuple[major, minor, patch: int]): string =
  $v.major & '.' & $v.minor & '.' & $v.patch