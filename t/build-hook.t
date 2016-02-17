#!perl6

use v6.c;

use Test;

use Panda::Tester;
use Panda::Builder;

my $wd = $*CWD.child('testmodules').child('with-build').Str;

$PANDATEST::RAN = False;

lives-ok {
    ok Panda::Tester.test($wd), "run test";
    ok Panda::Builder.build($wd), "run build";
    ok Panda::Builder.build($wd), "run build";
    ok $PANDATEST::RAN, "and it ran the builder";
}, "run test and build with a Build.pm present";


done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
