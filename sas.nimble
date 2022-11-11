# Package

version       = "0.1.0"
author        = "xcodz-dot"
description   = "SAS compiler"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
namedBin      = {"sas/sasbins/sas": "sas", "sas/sasbins/sasemu": "sasemu"}.toTable


# Dependencies

requires "nim >= 1.6.0"
requires "regex"
requires "argparse >= 3.0.1"