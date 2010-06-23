# =begin Pod
# 
# =head1 JSON::Tiny
# 
# C<JSON::Tiny> is a minimalistic module that reads and writes JSON.
# It supports strings, numbers, arrays and hashes (no custom objects).
# 
# =head1 Synopsis
# 
#     use JSON::Tiny;
#     my $json = to-json([1, 2, "a third item"]);
#     my $copy-of-original-data-structure = from-json($json);
# 
# =end Pod

module JSON::Tiny;

use JSON::Tiny::Actions;
use JSON::Tiny::Grammar;

proto to-json($d) is export { _tj($d) }

multi _tj(Real $d) { ~$d }
multi _tj(Bool $d) { $d ?? 'true' !! 'false'; }
multi _tj(Str  $d) {
    '"'
    ~ (~$d).trans(['"',  '\\',   "\b", "\f", "\n", "\r", "\t"]
            => ['\"', '\\\\', '\b', '\f', '\n', '\r', '\t'])\
            # RAKUDO: This would be nicer to write as <-[\c32..\c126]>,
            #         but Rakudo doesn't do \c yet. [perl #73698]
            .subst(/<-[\ ..~]>/, { ord(~$_).fmt('\u%04x') }, :g)
    ~ '"'
}
multi _tj(Array $d) {
    return  '[ '
            ~ (map { _tj($_) }, $d.values).join(', ')
            ~ ' ]';
}
multi _tj(Hash  $d) {
    return '{ '
            ~ (map { _tj(.key) ~ ' : ' ~ _tj(.value) }, $d.pairs).join(', ')
            ~ ' }';
}

multi _tj($d where { $d.notdef }) { 'null' }
multi _tj($s) {
    die "Can't serialize an object of type " ~ $s.WHAT.perl
}

sub from-json($text) is export {
    my $a = JSON::Tiny::Actions.new();
    my $o = JSON::Tiny::Grammar.parse($text, :actions($a));
    return $o.ast;
}
# vim: ft=perl6
