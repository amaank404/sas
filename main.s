.start _main

_main:
    # Initialize the counter, upper limit
    set t0 0
    set t1 10
    set t2 false
1:
    inc t0   # increment counter
    eq t2 t0 t1  # check for equality t2 <- (t0 == t1)
    jif t2 %2f   # If t2 is true, jump forward to local label 2
    jmp %1b      # else jump back to local label 1
2:
    err          # Throw an error intentionally thus exiting
