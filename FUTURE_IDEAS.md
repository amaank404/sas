# Future Ideas

This place stores all the possible ideas to implement. These ideas do not recieve any pull requests
and are directly maintained by me, the owner of the repository.

### Implement a equals to assignment for writing to memory and iobus

example

```
4[r1 100] <- r2  # Store a whole word
2[r1] <- r2      # Store a half word
1[0x122] <- r2   # Store a byte

io[r1 100] <- r2   # Store a byte in iobus address r1+100
```

Obviously, the compiler will only just translate this syntax to original boring instruction behind the scenes.

### Implement an easier operation for reading from memory and iobus

example

```
r1 <- 4[r2 100]   # Read a whole word from r2+100
r1 <- 2[r2]       # Read a half word from r2
r1 <- 1[100]      # Read a byte from address 100

r1 <- io[r2 102]  # Read a byte from iobus address r2+102
```

Obviously, the compiler will only just translate this syntax to original boring instruction behind the scenes.