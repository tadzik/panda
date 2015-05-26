use Test;
use Panda::Common;
use Panda::Builder;
use Shell::Command;

plan 7;

my $srcdir = 'testmodules';

lives-ok { Panda::Builder.build("$srcdir/dummymodule") };

ok "$srcdir/dummymodule/blib/lib/foo.pm.{compsuffix}".IO ~~  :f, 'module compiled';
ok "$srcdir/dummymodule/blib/lib/foo.pm".IO ~~   :f, 'and copied to blib';
ok "$srcdir/dummymodule/blib/lib/manual.pod".IO ~~  :f, 'pod copied too';
ok "$srcdir/dummymodule/blib/lib/bar.{compsuffix}".IO !~~ :f, 'pod not compiled';
ok "$srcdir/dummymodule/blib/lib/foo.js".IO ~~ :f,
   'random files also copied to blib';

lives-ok { Panda::Builder.build("$srcdir/testme1") };

rm_rf "$srcdir/dummymodule/blib";

# vim: ft=perl6
