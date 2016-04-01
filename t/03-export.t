use v6;

use Test;
use lib 'lib';

plan 4;

use File::Which :whence;
ok 1, "'use File::Which :whence' worked!";

my $perl6 = whence('perl6');
diag "Found perl6 at '$perl6' using whence";
ok $perl6.defined, "perl6 is found";
ok $perl6.IO ~~ :e, "perl6 file exists";
if $*DISTRO.is-win {
  skip("Windows does not set an executable file permission", 1);
} else {
  ok $perl6.IO ~~ :x, "perl6 and is an executable";
}
