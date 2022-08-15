.start _main

_main:
  set g0 1000
1:
  sub g0 1
  eq t0 g0 zero
  jif t0 %2f
  jmp %1b
2:
  jmp %2b