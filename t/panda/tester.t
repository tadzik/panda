use Test;
use Panda::Tester;

plan 2;

my $b = Panda::Tester.new(srcdir => 'testmodules');

my $p = Pies::Project.new(name => 'testme1');

lives_ok { $b.test($p) }, 'what should pass, passes';

$p = Pies::Project.new(name => 'testme2');

dies_ok { $b.test($p) }, 'what should fail, fails';

# vim: ft=perl6
