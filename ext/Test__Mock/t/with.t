use Test;
use Test::Mock;

plan 8;

class Glass { }
class Party { }
class Pub {
    method order_beer($pints) { }
    method throw($what) { }
}

my $p = mocked(Pub);

$p.order_beer(2);
$p.order_beer(1);
$p.throw(Party.new);

skip('with not supported yet', 8);
#check-mock($p,
#    *.called('order_beer', times => 2),
#    *.called('order_beer', times => 1, with => \(1)),
#    *.called('order_beer', times => 1, with => \(2)),
#    *.never-called('order_beer', with => \(10)),
#    *.called('throw', with => :(Party)),
#    *.never-called('throw', with => :(Glass)),
#    *.called('order_beer', times => 2, with => :($ where { $^n < 10 })),
#    *.never-called('order_beer', with => :($ where { $^n >= 10 })),
#);
