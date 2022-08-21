# SAS (Small and Simple)
Sas is a cpu architecture that was just created for emulators and other such
stuff. It is for fun and for learning basic assembly language. You can
look at [specs](specs.md) for more information.

## Compiler/Decompiler
The compiler is itself written in nim and the code is organized using modules.
Your main interest should be at module [sas/toolchain/parser](src/sas/toolchain/parser.nim). To
compile a source file. You should follow the following series in order. The
result of one to the other in chain: 

* `parseAsm`
* `resolveIncludeDirectives`
* `compile`

And to decompile you can use the following function

* `decompile`

To convert debuginfo from table to string. There are exported functions that
are originally located in [sas/toolchain/debuginfo](src/sas/toolchain/debuginfo.nim).

* `fromTextDebugInfo`
* `toTextDebugInfo`

## CLI
This compiler also provides a commandline interface. First, build the main
binary by using `nimble -d:release build`. This should build the sas binary
which you can invoke by `./sas --help`. The CLI interface is full featured.

## Compiler Compilation Flags
The compiler has some flags that alter the output binary.

| Flag | Effect |
| ---- | ------ |
| `-d:release` | Makes the compiler very fast |
| `--mm:orc --deepcopy:on` | Makes the compiler even faster |
| `-d:hideWarnings` | Resulting compiler will never have any warnings enabled |

## Specs
To basically learn about SAS, please look into [specs](specs.md). They contain
every detail. Even a reference 

# Licensing
LICENSED UNDER MIT LICENSE. LOOK AT [LICENSE](LICENSE) FILE FOR MORE DETAILS