import strutils

proc hexfilt*(s: string): string {.inline.} =
    s.replace("\n", "").replace(" ", "").toUpper