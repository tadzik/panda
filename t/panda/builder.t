use Test;
use Panda::Builder;

plan 3;

my $b = Panda::Builder.new(srcdir => 't/panda');

my $p = Pies::Project.new(name => 'dummymodule');


lives_ok { $b.build($p) };

ok 't/panda/dummymodule/blib/lib/foo.pir'.IO ~~ :f, 'module compiled';
ok 't/panda/dummymodule/blib/lib/foo.pm'.IO ~~ :f, 'module copied to blib';

run "rm -rf t/panda/dummymodule/blib";

# vim: ft=perl6
