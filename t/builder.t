use Test;
use Panda::Common;
use Panda::Builder;
use Shell::Command;

plan 2;

my $srcdir = 'testmodules';

lives-ok { Panda::Builder.build("$srcdir/dummymodule") };

lives-ok { Panda::Builder.build("$srcdir/testme1") };

# vim: ft=perl6
