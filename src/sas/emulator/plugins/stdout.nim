## A plugin for standard output, connects directly to
## address 0 of iobus with length of 1 byte

import ../types

proc stdoutplug_fn(iob: var array[256, uint8]) =
    let ch = iob[0]
    let chp = ch and 0b0111_1111'u8
    let chs = ch and 0b1000_0000'u8
    if chs > 0:
        write(io.stdout, chp.char)
        flushFile(io.stdout)
    iob[0] = chp

let stdoutPlugin*: Plugin = Plugin(onclock: stdoutplug_fn)