use v6;
BEGIN { @*INC.push('lib') };

use JSON::Tiny::Grammar;
use JSON::Tiny::Actions;
use Test;


my @t =
    '{ "a" : "b\u00E5" }' => { 'a' => 'bå' },
    '[ "\u2685" ]' => [ '⚅' ];

plan (+@t);
for @t -> $p {
    my $a = JSON::Tiny::Actions.new();
    my $o = JSON::Tiny::Grammar.parse($p.key, :actions($a));
    is-deeply $o.made, $p.value, "Correct data structure for «{$p.key}»"
        or say "# Got: {$o.made.perl}\n# Expected: {$p.value.perl}";
}
