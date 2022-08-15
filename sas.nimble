# Package

version       = "1.0.0"
author        = "xcodz-dot"
description   = "SAS compiler"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["sas"]


# Dependencies

requires "nim >= 1.6.0"
requires "regex"