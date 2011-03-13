use Test;
use Panda::Tester;
use Panda::Resources;

plan 2;

my $srcdir = 'testmodules';

my $r = Panda::Resources.new(srcdir => $srcdir);
my $b = Panda::Tester.new(resources => $r);

my $p = Pies::Project.new(name => 'testme1');

lives_ok { $b.test($p) }, 'what should pass, passes';

$p = Pies::Project.new(name => 'testme2');

dies_ok { $b.test($p) }, 'what should fail, fails';

# vim: ft=perl6
