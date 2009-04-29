use v6;
BEGIN { @*INC.push('lib') };
use JSON::Tiny::Grammar;
use JSON::Tiny::Actions;
use Test;

my @t = 
   '{ "a" : 1 }' => { a => 1 },
   '[]'          => [],
   '[ "a", "b"]' => [ "a", "b" ],
   '[3]'         => [3],
   '[{ "foo" : { "bar" : 3 } }, 78]' => [{ foo => { bar => 3 }}, 78],
   '[{ "a" : 3, "b" : 4 }]' => [{ a => 3, b => 4}],
;
plan +@t;

for @t -> $p {
    my $a = JSON::Tiny::Actions.new();
    my $o = JSON::Tiny::Grammar.parse($p.key, :action($a));
    is_deeply $o.ast, $p.value, "Correct data structure for «{$p.key}»"
        or say "# Got: {$o.ast.perl}\n# Expected: {$p.value.perl}";
}

# vim: ft=perl6
