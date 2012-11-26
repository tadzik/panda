use Test;
use Panda::Builder;
use Panda::Resources;
use Shell::Command;

plan 6;

my $srcdir = 'testmodules';

my $r = Panda::Resources.new(srcdir => $srcdir);
my $b = Panda::Builder.new(resources => $r);

my $p = Pies::Project.new(name => 'dummymodule');


lives_ok { $b.build($p) };

ok "$srcdir/dummymodule/blib/lib/foo.pir".IO ~~  :f, 'module compiled';
ok "$srcdir/dummymodule/blib/lib/foo.pm".IO ~~   :f, 'and opied to blib';
ok "$srcdir/dummymodule/blib/lib/manual.pod".IO ~~  :f, 'pod copied too';
ok "$srcdir/dummymodule/blib/lib/bar.pir".IO !~~ :f, 'pod not compiled';
ok "$srcdir/dummymodule/blib/lib/foo.js".IO ~~ :f,
   'random files also copied to blib';

rm_rf "$srcdir/dummymodule/blib";

# vim: ft=perl6
