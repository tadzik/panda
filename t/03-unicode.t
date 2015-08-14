use v6;
BEGIN { @*INC.push('lib') };

use JSON::Fast;
use Test;


my @t =
    '{ "a" : "b\u00E5" }' => { 'a' => 'bå' },
    '[ "\u2685" ]' => [ '⚅' ];

plan (+@t * 2);
for @t -> $p {
    my $json = from-json($p.key);
    is-deeply $json, $p.value, "Correct data structure for «{$p.key}»";
    is to-json($json).lc, $p.key.lc;
}
