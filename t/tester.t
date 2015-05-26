use Test;
use Panda::Tester;

plan 2;

my $m1 = 'testmodules/testme1';
my $m2 = 'testmodules/testme2';

lives-ok { Panda::Tester.test($m1) }, 'what should pass, passes';
dies-ok  { Panda::Tester.test($m2) }, 'what should fail, fails';

# vim: ft=perl6
