use Test;

use JSON::Fast;

my @s =
        'Int'            => [ 1 ],
        'Rat'            => [ 3.2 ],
        'Str'            => [ 'one' ],
        'Str with quote' => [ '"foo"'],
        'Undef'          => [ {}, 1 ],
        'other escapes'  => [ "\\/\"\n\r\tfoo\\"],
        'Non-ASCII'      => [ 'möp stüff' ],
        'Empty Array'    => [ ],
        'Array of Int'   => [ 1, 2, 3, 123123123 ],
        'Array of Num'   => [ 1.3, 2.8, 32323423.4, 4.0 ],
        'Array of Str'   => [ <one two three gazooba> ],
        'Empty Hash'     => {},
        'Hash of Int'    => { :one(1), :two(2), :three(3) },
        'Hash of Num'    => { :one-and-some[1], :almost-pie(3.3) },
        'Hash of Str'    => { :one<yes_one>, :two<but_two> },
        'Array of Stuff' => [ { 'A hash' => 1 }, [<an array again>], 2],
        'Hash of Stuff'  =>
                            {
                                keyone   => [<an array>],
                                keytwo   => "A string",
                                keythree => { "another" => "hash" },
                                keyfour  => 4,
                                keyfive  => False,
                                keysix   => True,
                                keyseven => 3.2,
                            };

plan +@s;

for @s.kv -> $k, $v {
    my $r = from-json( to-json( $v.value, :!pretty ) );
    todo('known type mismatches') if $k == 9;
    is-deeply $r, $v.value, $v.key;
}

# vim: ft=perl6
