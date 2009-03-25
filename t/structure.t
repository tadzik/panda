use v6;
BEGIN { @*INC.push('lib') };
use JSON::Tiny::Grammar;
use JSON::Tiny::Actions;
use Test;
plan 1;

my @t = 
   '{ "a" : 1 }' => { a => 1 },
;

for @t -> $p {
    my $a = JSON::Tiny::Actions.new();
    my $o = JSON::Tiny::Grammar.parse($p.key, :action($a));
    is_deeply $o.ast, $p.value, "Correct data structure for «{$p.key}»"
        or say "# Got: {$o.ast.perl}\n# Expected: {$p.value.perl}";
}

# vim: ft=perl6
