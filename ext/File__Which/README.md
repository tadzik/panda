# File::Which

This is a Perl 6 Object-oriented port of [File::Which (CPAN)](
https://metacpan.org/pod/File::Which).

File::Which finds the full or relative paths to an executable program on the
system. This is normally the function of which utility which is typically
implemented as either a program or a built in shell command. On some unfortunate
platforms, such as Microsoft Windows it is not provided as part of the core
operating system.

This module provides a consistent API to this functionality regardless of the
underlying platform.

```Perl6
use File::Which :whence;

# All perl executables in PATH
say which('perl6', :all);

# First executable in PATH
say which('perl6');

# Same as which('perl6')
say whence('perl6');
```

## Build Status

| Operating System  |   Build Status  | CI Provider |
| ----------------- | --------------- | ----------- |
| Linux / Mac OS X  | [![Build Status](https://travis-ci.org/azawawi/perl6-file-which.svg?branch=master)](https://travis-ci.org/azawawi/perl6-file-which)  | Travis CI |
| Windows 7 64-bit  | [![Build status](https://ci.appveyor.com/api/projects/status/github/azawawi/perl6-file-which?svg=true)](https://ci.appveyor.com/project/azawawi/perl6-file-which/branch/master)  | AppVeyor |

## Installation

To install it using Panda (a module management tool bundled with Rakudo Star):

```
$ panda update
$ panda install File::Which
```

## Testing

To run tests:

```
$ prove -e "perl6 -Ilib"
```

## Author

Perl 6 port:
- Ahmad M. Zawawi, azawawi on #perl6, https://github.com/azawawi/

Perl 5 version:
- Author: Per Einar Ellefsen <pereinar@cpan.org>
- Maintainers:
  - Adam Kennedy <adamk@cpan.org>
  - Graham Ollis <plicease@cpan.org>

## License

MIT License
