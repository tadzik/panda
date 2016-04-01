# Shell::Command

Provides cross-platform routines emulating common \*NIX shell commands

## Build Status

| Operating System  |   Build Status  | CI Provider |
| ----------------- | --------------- | ----------- |
| Linux / Mac OS X  | [![Build Status](https://travis-ci.org/tadzik/Shell-Command.svg?branch=master)](https://travis-ci.org/tadzik/Shell-Command)  | Travis CI |
| Windows 7 64-bit  | [![Build status](https://ci.appveyor.com/api/projects/status/github/tadzik/Shell-Command?svg=true)](https://ci.appveyor.com/project/tadzik/Shell-Command/branch/master)  | AppVeyor |

## Example

```Perl6
use v6;
use Shell::Command;

# Recursive folder copy
cp 't/dir1', 't/dir2', :r;

# Remove directory
rmdir 't/dupa/foo/bar';

# Make path
mkpath 't/dir2';

# Remove path
rm_rf 't/dir2';

# Find perl6 in executable path
my $perl6_path = which('perl6');
```
## See Also
- [Shell::Command](https://metacpan.org/pod/Shell::Command)

## Author

- Tadeusz “tadzik” Sośnierz"

## Contributors
- Dagur Valberg Johansson
- Elizabeth Mattijsen
- Filip Sergot
- Geoffrey Broadwell
- GlitchMr
- Heather
- Kamil Kułaga
- Moritz Lenz
- Steve Mynott
- timo
- Tobias Leich
- Tim Smith
- Ahmad M. Zawawi (azawawi @ #perl6)

## LICENSE

MIT License
