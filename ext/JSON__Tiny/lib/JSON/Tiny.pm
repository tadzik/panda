=begin pod

=head1 JSON::Tiny

C<JSON::Tiny> is a minimalistic module that reads and writes JSON.
It supports strings, numbers, arrays and hashes (no custom objects).

=head1 Synopsis

    use JSON::Tiny;
    my $json = to-json([1, 2, "a third item"]);
    my $copy-of-original-data-structure = from-json($json);

=end pod

unit module JSON::Tiny;

use JSON::Tiny::Actions;
use JSON::Tiny::Grammar;

class X::JSON::Tiny::Invalid is Exception {
    has $.source;
    method message { "Input ($.source.chars() characters) is not a valid JSON string" }
}

proto to-json($) is export {*}

multi to-json(Real:D $d) { ~$d }
multi to-json(Bool:D $d) { $d ?? 'true' !! 'false'; }
multi to-json(Str:D  $d) {
    '"'
    ~ $d.trans(['"',  '\\',   "\b", "\f", "\n", "\r", "\t"]
            => ['\"', '\\\\', '\b', '\f', '\n', '\r', '\t'])\
            .subst(/<-[\c32..\c126]>/, {
                $_.Str.encode('utf-16').values».fmt('\u%04x').join
            }, :g)
    ~ '"'
}
multi to-json(Positional:D $d) {
    return  '[ '
            ~ $d.flatmap(&to-json).join(', ')
            ~ ' ]';
}
multi to-json(Associative:D  $d) {
    return '{ '
            ~ $d.flatmap({ to-json(.key) ~ ' : ' ~ to-json(.value) }).join(', ')
            ~ ' }';
}

multi to-json(Mu:U $) { 'null' }
multi to-json(Mu:D $s) {
    die "Can't serialize an object of type " ~ $s.WHAT.perl
}

sub from-json($text) is export {
    my $a = JSON::Tiny::Actions.new();
    my $o = JSON::Tiny::Grammar.parse($text, :actions($a));
    unless $o {
        X::JSON::Tiny::Invalid.new(source => $text).throw;
    }
    
    return $o.made;
}
# vim: ft=perl6
