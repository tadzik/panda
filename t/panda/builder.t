use Test;
use Panda::Builder;

plan 3;

my $srcdir = 'testmodules';

my $b = Panda::Builder.new(srcdir => $srcdir);

my $p = Pies::Project.new(name => 'dummymodule');


lives_ok { $b.build($p) };

ok "$srcdir/dummymodule/blib/lib/foo.pir".IO ~~ :f, 'module compiled';
ok "$srcdir/dummymodule/blib/lib/foo.pm".IO ~~ :f, 'module copied to blib';

run "rm -rf $srcdir/dummymodule/blib $srcdir/dummymodule/Makefile";

# vim: ft=perl6
