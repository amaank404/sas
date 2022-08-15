"""
Standard Compiler for sas and it is also
highly unoptimized, so you should not expect
much from it. A rewrite of this compiler in 
nim is also available for use. It offers much
more performance and is also much more bugfree.
"""

from argparse import ArgumentParser
from typing import List
import re
from pprint import pprint
import os


class ParseError(Exception):
    pass


# A mapping of all possible pseudo instructions.
pseudoinstructions = {
    ("add", "r", "r", "r"): "add {a0} {a1} {a2} 0",
    ("add", "r", "r"): "add {a0} {a0} {a1} 0",
    ("add", "r", "l"): "add {a0} {a0} zero {a1}",
    ("add", "r", "r", "l"): "add {a0} {a1} zero {a2}",
    ("mov", "r", "r"): "add {a0} {a1} zero zero",
    ("set", "r", "l"): "add {a0} zero zero {a1}",
    ("sub", "r", "r", "r"): "sub {a0} {a1} {a2} 0",
    ("sub", "r", "r"): "sub {a0} {a0} {a1} 0",
    ("sub", "r", "l"): "sub {a0} {a0} zero {a1}",
    ("sub", "r", "r", "l"): "sub {a0} {a1} zero {a2}",
    ("mul", "r", "r", "r"): "mul {a0} {a1} {a2} 1",
    ("mul", "r", "r"): "mul {a0} {a0} {a1} 1",
    ("mul", "r", "l"): "mul {a0} {a0} one {a1}",
    ("mul", "r", "r", "l"): "mul {a0} {a1} one {a2}",
    ("div", "r", "r", "r"): "div {a0} {a1} {a2} 0",
    ("div", "r", "r"): "div {a0} {a0} {a1} 0",
    ("div", "r", "l"): "div {a0} {a0} zero {a1}",
    ("div", "r", "r", "l"): "div {a0} {a1} zero {a2}",
    ("div", "r", "l", "r"): "divr {a0} {a2} {a1}",
    ("mod", "r", "r", "r"): "mod {a0} {a1} {a2} 0",
    ("mod", "r", "r"): "mod {a0} {a0} {a1} 0",
    ("mod", "r", "l"): "mod {a0} {a0} zero {a1}",
    ("mod", "r", "r", "l"): "mod {a0} {a1} zero {a2}",
    ("mod", "r", "l", "r"): "modr {a0} {a2} {a1}",
    ("ldb", "r", "r"): "ldb {a0} {a1} 0",
    ("ldb", "r", "l"): "ldb {a0} zero {a1}",
    ("ldh", "r", "r"): "ldh {a0} {a1} 0",
    ("ldh", "r", "l"): "ldh {a0} zero {a1}",
    ("ldw", "r", "r"): "ldw {a0} {a1} 0",
    ("ldw", "r", "l"): "ldw {a0} zero {a1}",
    ("jmp", "r", "i"): "add ip {a0} zero {a1}",
    ("jmp", "r"): "add ip {a0} zero 0",
    ("jmp", "l"): "add ip zero zero {a0}",
    ("stb", "r", "r"): "stb {a0} 0 {a1}",
    ("stb", "l", "r"): "stb zero {a0} {a1}",
    ("sth", "r", "r"): "sth {a0} 0 {a1}",
    ("sth", "l", "r"): "sth zero {a0} {a1}",
    ("stw", "r", "r"): "stw {a0} 0 {a1}",
    ("stw", "l", "r"): "stw zero {a0} {a1}",
    ("push", "r"): "sub sp sp zero 4\nstw sp 0 {a0}",
    ("pop", "r"): "ldw {a0} sp 0\nadd sp sp zero 4",
    (
        "call",
        "l",
    ): "add t0 ip zero 32\nsub sp sp zero 4\nstw sp 0 t0\nadd ip zero zero {a0}",
    (
        "call",
        "r",
    ): "add t0 ip zero 32\nsub sp sp zero 4\nstw sp 0 t0\nadd ip zero {a0} 0",
    ("ret",): "ldw t0 sp 0\nadd sp sp zero 4\nadd ip t0 zero 0",
    ("ecall",): "add t0 ip zero 32\nsub sp sp zero 4\nstw sp 0 t0\nadd ip zero ct 0",
    ("gt", "r", "r"): "gt {a0} {a0} {a1}",
    ("lt", "r", "r", "r"): "gt {a0} {a2} {a1}",
    ("lt", "r", "r"): "gt {a0} {a1} {a0}",
    ("eq", "r", "r"): "eq {a0} {a0} {a1}",
    ("not", "r"): "not {a0} {a0}",
    ("neq", "r", "r", "r"): "eq {a0} {a1} {a2}\nnot {a0} {a0}",
    ("neq", "r", "r"): "eq {a0} {a0} {a1}\nnot {a0} {a0}",
    ("or", "r", "r", "r"): "or {a0} {a1} {a2} 0",
    ("or", "r", "r"): "or {a0} {a0} {a1} 0",
    ("or", "r", "r", "l"): "or {a0} {a0} {a1} {a2}",
    ("or", "r", "l"): "or {a0} {a0} zero {a1}",
    ("and", "r", "r"): "and {a0} {a0} {a1}",
    ("xor", "r", "r", "r"): "xor {a0} {a1} {a2} 0",
    ("xor", "r", "r", "l"): "xor {a0} {a1} zero {a2}",
    ("xor", "r", "r"): "xor {a0} {a0} {a1} 0",
    ("xor", "r", "l"): "xor {a0} {a0} zero {a1}",
    ("jif", "r", "l"): "jif {a0} zero {a1}",
    ("jif", "r", "r"): "jif {a0} {a1} 0",
    ("shl", "r", "r", "r"): "shl {a0} {a1} {a2} 0",
    ("shl", "r", "r"): "shl {a0} {a0} {a1} 0",
    ("shl", "r", "l"): "shl {a0} {a0} zero {a1}",
    ("shr", "r", "r", "r"): "shr {a0} {a1} {a2} 0",
    ("shr", "r", "r"): "shr {a0} {a0} {a1} 0",
    ("shr", "r", "l"): "shr {a0} {a0} zero {a1}",
}

esctable = {
    "\\n": "\n",
    "\\r": "\r",
    "\\a": "\a",
    "\\0": "\0",
    "\\t": "\t",
    "\\'": "'",
    '\\"': '"',
    "\\\\": "\\",
    "\\w": " ",
}


const = {
    "word": 4,
    "half": 2,
    "byte": 1,
    "true": 1,
    "false": 0,
}

reglist = {"zero": 0, "one": 1, "sp": 2, "ip": 3, "mp": 13, "ct": 21}
reglist.update({f"r{x}": x + 2 for x in range(28)})
reglist.update({f"g{x}": x + 4 for x in range(9)})
reglist.update({f"t{x}": x + 14 for x in range(7)})
reglist.update({f"a{x}": x + 22 for x in range(8)})


class Tokens:
    comment = re.compile(r"\#.*")
    directive = re.compile(r"\.(?P<name>\S+)(\s+(?P<args>.*)|\s*)")
    stringliteral = re.compile(r'"(?P<data>(\\.|[^"\\])*)(?<!\\)"')
    hexliteral = re.compile(r"(?P<sign>[\-\+])?0[xX](?P<hex>[a-fA-F0-9]+)")
    octalliteral = re.compile(r"(?P<sign>[\-\+])?0[oO](?P<oct>[0-7]+)")
    binaryliteral = re.compile(r"(?P<sign>[\-\+])?0[bB](?P<bin>[10]+)")
    charliteral = re.compile(r"'(?P<data>\\.|[^'\\])((?<!\\)|(?<=\\\\))'")
    numliteral = re.compile(r"(?P<sign>[\-\+])?(?P<int>\d+)")
    constliteral = re.compile(r"(word|half|byte|true|false)")
    label = re.compile(r"%[^\d].*")
    locallabel = re.compile(r"%\d+(f|b)")
    labelident = re.compile(r"(?P<name>[^\:]+)\:")
    instruction = re.compile(r"(?P<name>\S+)\s+(?P<args>.*)")
    bareinstruction = re.compile(r"(?P<name>\S+)(?P<args>)")
    registerliteral = re.compile(r"(zero|sp|ip|mp|ct|t[0-6]|g[0-8]|)")
    space = re.compile(r"\s+")


class Directive:
    def __init__(self, match: re.Match):
        self.name = match.group("name")
        self.args = match.group("args")

    def __repr__(self) -> str:
        return f"d: .{self.name} {self.args}"


class RawData:
    def __init__(self, data: bytes):
        self.data = data
    def __repr__(self):
        drepr = repr(self.data)
        if len(drepr) >=25:
            return "Raw:"+drepr[:10]+' [...] '+drepr[-10:]
        else:
            return "Raw:"+drepr

    def __len__(self) -> int:
        return len(self.data)
    
    def getdata(self) -> bytes:
        return self.data


class Instruction:
    def __init__(self, match: re.Match):
        self.ident = match.group("name")
        raw_args = match.group("args")
        self.args = Tokens.space.split(raw_args)
        self.signature = [self.ident]
        for i, v in enumerate(self.args):
            if (l := iliteral(v)) is not None:
                self.signature.append("l")
                self.args[i] = l
            elif isreg(v):
                self.signature.append("r"),
                self.args[i] = reglist[v]
            elif v == "":
                pass
            elif Tokens.label.match(v) or Tokens.locallabel.match(v):
                self.signature.append("l")
                self.args[i] = v.strip()
            else:
                raise ParseError(f"Unrecognized Argument: {repr(v)}")

    def abs(self) -> List["Instruction"]:
        """
        Turns any pseudo instructions to real instructions
        """
        if tuple(self.signature) in pseudoinstructions:
            fstring = pseudoinstructions[tuple(self.signature)]
            instructions = fstring.format(
                **{f"a{x}": v for x, v in enumerate(self.args)}
            ).split("\n")
            i = [Instruction(Tokens.instruction.match(x)) for x in instructions]
            return i
        else:
            return [self]

    def __eq__(self, o: "Instruction") -> bool:
        return self.signature == o.signature

    def __repr__(self) -> str:
        return f"i: {self.ident} {' '.join(map(str, self.args))}"
    
    def __len__(self) -> int:
        """
        Assuming that the instruction is absolute
        """
        return 8

    def getdata(self) -> bytes:
        opcode = 0
        arg1 = 0
        arg2 = 0
        arg3 = 0
        arg4 = 0
        nic = 0
        if self.ident == "err":
            opcode = 0x00
        elif self.ident == "nop":
            opcode = 0x01
        elif self.ident == "add":
            opcode = 0x02
            arg1, arg2, arg3, arg4 = self.args
        elif self.ident == "sub":
            opcode = 0x17
            arg1, arg2, arg3, arg4 = self.args
        elif self.ident == "mul":
            opcode = 0x03
            arg1, arg2, arg3, arg4 = self.args
        elif self.ident == "div":
            opcode = 0x04
            arg1, arg2, arg3, arg4 = self.args
        elif self.ident == "divr":
            opcode = 0x05
            arg1, arg4 = self.args[:2]
            arg2 = self.args[2]
        elif self.ident == "mod":
            opcode = 0x06
            arg1, arg2, arg3, arg4 = self.args
        elif self.ident == "modr":
            opcode = 0x07
            arg1, arg4 = self.args[:2]
            arg2 = self.args[2]
        elif self.ident == "ldb":
            opcode = 0x08
            arg1, arg2 = self.args[:2]
            arg4 = self.args[2]
        elif self.ident == "ldh":
            opcode = 0x09
            arg1, arg2 = self.args[:2]
            arg4 = self.args[2]
        elif self.ident == "ldw":
            opcode = 0x0a
            arg1, arg2 = self.args[:2]
            arg4 = self.args[2]
        elif self.ident == "stb":
            opcode = 0x0b
            arg1, arg4 = self.args[:2]
            arg2 = self.args[2]
        elif self.ident == "sth":
            opcode = 0x0c
            arg1, arg4 = self.args[:2]
            arg2 = self.args[2]
        elif self.ident == "stw":
            opcode = 0x0d
            arg1, arg4 = self.args[:2]
            arg2 = self.args[2]
        elif self.ident == "gt":
            opcode = 0x0e
            arg1, arg2, arg3 = self.args[:3]
        elif self.ident == "eq":
            opcode = 0x0f
            arg1, arg2, arg3 = self.args[:3]
        elif self.ident == "not":
            opcode = 0x10
            arg1, arg2 = self.args[:2]
        elif self.ident == "or":
            opcode = 0x11
            arg1, arg2, arg3, arg4 = self.args
        elif self.ident == "and":
            opcode = 0x12
            arg1, arg2, arg3 = self.args[:3]
        elif self.ident == "xor":
            opcode = 0x13
            arg1, arg2, arg3, arg4 = self.args
        elif self.ident == "jif":
            opcode = 0x14
            arg2, arg3, arg4 = self.args[:3]
        elif self.ident == "shl":
            opcode = 0x15
            arg1, arg2, arg3, arg4 = self.args
        elif self.ident == "shr":
            opcode = 0x16
            arg1, arg2, arg3, arg4 = self.args
        elif self.ident == "iow":
            opcode = 0x18
            arg2, arg4, arg3 = self.args[0:3]
        elif self.ident == "ior":
            opcode = 0x19
            arg1, arg2, arg4 = self.args[0:3]
        else:
            raise ParseError(f"Unrecognized identifier: {{{self.ident}}}")
        if arg1 == 3:
            nic = 1
        try:
            o = (((opcode | nic << 7) << 56) | (arg1 << 48) | (arg2 << 40) | (arg3 << 32) | arg4).to_bytes(8, 'big', signed=False)
        except TypeError:
            breakpoint()
        return o

def compile(code: str, parse_only: bool = False, libpaths = None):
    if libpaths is None:
        libpaths = []
    code: List[str] = code.splitlines()
    for i in range(len(code)):
        code[i] = code[i].strip()
        code[i] = Tokens.comment.sub("", code[i])

    while "" in code:
        code.remove("")

    # Code upto here has been cleaned

    codestructure = []

    # Pass 1: Parse all the lines with regex paterns
    for i, v in enumerate(code):
        if match := Tokens.directive.match(v):
            codestructure.append(Directive(match))
        elif match := Tokens.instruction.match(v):
            codestructure.append(Instruction(match))
        elif match := Tokens.labelident.match(v):
            codestructure.append(match.group("name"))
        elif bool(match := Tokens.bareinstruction.match(v)) and " " not in v:
            codestructure.append(Instruction(match))
        else:
            raise ParseError(f"No valid match {{{i}}}: {{{v}}}")



    codestructure2 = []
    labellocations = {}
    labelsetlocations = {}
    mem = 0

    for v in codestructure:
        if isinstance(v, Directive):
            if v.name == "include":
                string_data = list(
                    Tokens.stringliteral.match(v.args.strip()).group("data")
                )
                replacement_tasks = []
                for i, v in enumerate(string_data):
                    if v == "\\":
                        replacement_tasks.append(i)
                done = 0
                for x in replacement_tasks:
                    string_data[x - done] = esctable["\\" + string_data[x - done + 1]]
                    done += 1

                string_data = "".join(string_data)
                pfound = False
                for x in libpaths:
                    if os.path.exists(p := os.path.join(x, string_data)):
                        string_data = p
                        pfound = True
                        break
                if not pfound:
                    raise ParseError(f"No library found named {{{string_data}}} in libraries: {libpaths}")
                with open(string_data, "r") as file:
                    data = file.read()
                codestructure2.extend(compile(data, True))
            else:
                codestructure2.append(v)
        else:
            codestructure2.append(v)
    
    codestructure = codestructure2
    codestructure2 = []

    if parse_only:
        return codestructure

    codestructure.append("MEMORY_START")  # Append the memory start label

    # Pass 2: Parse Assembler Directives for include and constants.
    for v in codestructure:
        if isinstance(v, Directive):
            if v.name == "byte":
                codestructure2.append(
                    RawData(iliteral(v.args.strip()).to_bytes(1, "big", signed=True))
                )
            elif v.name == "zero":
                codestructure2.append(
                    RawData(b"".ljust(iliteral(v.args.strip()), b"\0"))
                )
            elif v.name == "nop":
                codestructure2.extend(
                    [
                        Instruction(Tokens.instruction.match("nop"))
                        for _ in range(iliteral(v.args.strip()))
                    ]
                )
            elif v.name == "half":
                codestructure2.append(
                    RawData(iliteral(v.args.strip()).to_bytes(2, "big", signed=True))
                )
            elif v.name == "word":
                codestructure2.append(
                    RawData(iliteral(v.args.strip()).to_bytes(4, "big", signed=True))
                )
            elif v.name == "memory":
                labelname, literal = Tokens.space.split(v.args.strip())
                literal = iliteral(literal.strip())
                location = mem  # Get the location by reading the memory counter
                mem += literal  # Increment the counter.
                if labelname in labellocations:
                    print(f"Warning: Duplicate Label {repr(labelname)}")
                labellocations[labelname] = location
            elif v.name == "labelset":
                labelname, literal = Tokens.space.split(v.args.strip())
                literal = iliteral(literal.strip())
                if labelname in labelsetlocations:
                    print(f"Warning: Duplicate LabelSet {repr(labelname)}")
                labelsetlocations[labelname] = literal
            elif v.name in ("string", "dump"):
                string_data = list(
                    Tokens.stringliteral.match(v.args.strip()).group("data")
                )
                replacement_tasks = []
                for i, x in enumerate(string_data):
                    if x == "\\":
                        replacement_tasks.append(i)
                done = 0
                for x in replacement_tasks:
                    string_data[x - done] = esctable["\\" + string_data[x - done + 1]]
                    done += 1
                codestructure2.append(
                    RawData(
                        "".join(string_data).encode("utf-8") + b"\0"
                        if v.name == "string"
                        else b""
                    )
                )
            elif v.name == "start":  # Jump instruction
                codestructure2.append(
                    Instruction(Tokens.instruction.match("jmp %" + v.args.strip()))
                )
            else:
                raise ParseError(f"Unknown Directive: {repr(v.name)}")
        else:
            codestructure2.append(v)
    del codestructure
    codestructure3 = []

    # Pass 3: Replace Pseudo Instructions
    for i, v in enumerate(codestructure2):
        if isinstance(v, Instruction):
            codestructure3.extend(v.abs())
        else:
            codestructure3.append(v)

    del codestructure2

    # At this point, we have completely parsed all the instruction
    # to their final executable form. Now, we need to parse the labels
    # and form a map of their code addresses.
    #
    # We will use a list of address for anonymous labels and a specific
    # address for named lables. Overlapping naming of named labels will
    # be considered as a warning
    i = 0
    codestructure4 = []
    for x in codestructure3:
        if isinstance(x, str):
            if x.isnumeric():
                labellocations.setdefault(x, [])
                labellocations[x].append(i)
            else:
                if x in labellocations.keys():
                    print(f"Warning: Label {repr(x)} has been repeated")
                labellocations[x] = i
        elif hasattr(x, '__len__'):
            i += len(x)
        if not isinstance(x, str):
            codestructure4.append(x)
    del codestructure3

    # All labels have been parsed and now we can replace
    # label arguments of instructions to absolute values.
    ci = 0
    for x in codestructure4:
        if isinstance(x, Instruction):
            for i, v in enumerate(x.args):
                if isinstance(v, str):
                    if v.startswith("%") and not v[1:-1].isnumeric():
                        if v[1:] not in labellocations.keys():
                            raise ParseError(f"No label named {{{v[1:]}}}")
                        x.args[i] = labellocations[v[1:]]
                    elif v.startswith("%") and v[1:-1].isnumeric():
                        if v[-1] == 'b':
                            for x2 in reversed(labellocations[v[1:-1]]):
                                if ci >= x2:
                                    x.args[i] = x2
                        elif v[-1] == 'f':
                            for x2 in labellocations[v[1:-1]]:
                                if ci < x2:
                                    x.args[i] = x2
        ci += len(x)
    for k, v in labelsetlocations.items():
        labellocations[k] = v

    # All variables have been resolved and we should now
    # only be left with either instruction or raw data.
    #
    # Here, we will use the `getdata` method on all remaining
    # objects to convert them to bytes that can be directly
    # concatenated
    o = b''
    print(codestructure4)
    for x in codestructure4:
        o += x.getdata()

    return o


def iliteral(s: str) -> int:
    if m := Tokens.hexliteral.match(s):
        res = int(m.group("hex"), 16)
        if m.group("sign") == "-":
            res = -res
        return res
    elif m := Tokens.octalliteral.match(s):
        res = int(m.group("oct"), 8)
        if m.group("sign") == "-":
            res = -res
        return res
    elif m := Tokens.binaryliteral.match(s):
        res = int(m.group("bin"), 2)
        if m.group("sign") == "-":
            res = -res
        return res
    elif m := Tokens.charliteral.match(s):
        res = m.group("data")
        if res.startswith("\\") and len(res) == 2:
            res = esctable[res]
        return ord(res)
    elif m := Tokens.numliteral.match(s):
        res = int(m.group("int"), 10)
        if m.group("sign") == "-":
            res = -res
        return res
    elif m := Tokens.constliteral.match(s):
        return const[m.string]


def isreg(s: str) -> bool:
    return s in reglist.keys()


def main():
    parser = ArgumentParser()
    parser.add_argument("file", help="File to compile", metavar="ASMFILE")
    parser.add_argument("-o", "--out", help="Output Binary File", metavar="OUTPUTFILE", default=None)
    parser.add_argument("-l", "--lib", help="Library source path to include", metavar="DIRECTORY", default=[], action="append")
    args = parser.parse_args()
    args.lib.append(os.path.dirname(__file__)+"/lib")
    with open(args.file) as file:
        code = file.read()
    out = compile(code, libpaths=args.lib)
    if args.out is None:
        args.out = args.file.rsplit('.', 1)[0]+'.bin'
    with open(args.out, "wb") as file:
        file.write(out)


if __name__ == "__main__":
    main()
