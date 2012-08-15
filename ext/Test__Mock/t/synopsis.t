use Test;
use Test::Mock;

plan 2;

class Foo {
    method lol() { 'rofl' }
    method wtf() { 'oh ffs' }
}

my $x = mocked(Foo);

$x.lol();
$x.lol();

check-mock($x,
    *.called('lol', times => 2),
    *.never-called('wtf'),
);
