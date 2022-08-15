type
  Directive* = object
    args*: string
    name*: string

  RawData* = object
    data*: seq[byte]

  RawInstruction* = object
    ident*: string
    args*: seq[string]
    signature*: string
  
  Instruction* = object
    opcode*: uint8
    rd1*: uint8
    rs1*: uint8
    rs2*: uint8
    imm*: uint32
  
  NodeKind* = enum
    nkRawData,
    nkDirective,
    nkInstruction,
    nkRawInstruction,
    nkLabel,
  
  Node* = ref object
    case kind*: NodeKind
    of nkRawData: rawVal*: RawData
    of nkDirective: dirVal*: Directive
    of nkInstruction: insVal*: Instruction
    of nkRawInstruction: rinsVal*: RawInstruction
    of nkLabel: labelIdent*: string