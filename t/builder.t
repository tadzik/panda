use Test;
use Panda::Builder;
use Shell::Command;

plan 6;

my $srcdir = 'testmodules';

lives_ok { Panda::Builder.build("$srcdir/dummymodule") };

ok "$srcdir/dummymodule/blib/lib/foo.pir".IO ~~  :f, 'module compiled';
ok "$srcdir/dummymodule/blib/lib/foo.pm".IO ~~   :f, 'and opied to blib';
ok "$srcdir/dummymodule/blib/lib/manual.pod".IO ~~  :f, 'pod copied too';
ok "$srcdir/dummymodule/blib/lib/bar.pir".IO !~~ :f, 'pod not compiled';
ok "$srcdir/dummymodule/blib/lib/foo.js".IO ~~ :f,
   'random files also copied to blib';

rm_rf "$srcdir/dummymodule/blib";

# vim: ft=perl6
