=begin Pod

=head1 JSON::Tiny

C<JSON::Tiny> is a minimalistic module that reads and writes JSON.
It supports strings, numbers, arrays and hashes (no custom objects).

=head1 Synopsis

    use JSON::Tiny;
    my $json = to-json([1, 2, "a third item"]);
    my $copy-of-original-data-structure = from-json($json);

=end Pod

module JSON::Tiny {
    use JSON::Tiny::Actions;
    use JSON::Tiny::Grammar;

    sub from-json($text) is export {
        my $a = JSON::Tiny::Actions.new();
        my $o = JSON::Tiny::Grammar.parse($text, :action($a));
        return $o.ast;
    }

    multi to-json(Num $d) is export { $d }
    multi to-json(Int $d) { $d }
    multi to-json(Str $d) { 
        # RAKUDO BUG #66596 (can't .subst in multis)
        string-to-json($d);
    }
    multi to-json(Array $data) {
        return  '[ ' 
               ~ (map { to-json($_) }, $data.values).join(', ')
               ~ ' ]';
    }
    multi to-json(Hash  $data) {
        return '{ '
               ~ (map { to-json(.key) ~ ' : ' ~ to-json(.value) }, $data.pairs).join(', ')
               ~ ' }';
    }
    multi to-json(Bool  $data) { $data ?? 'true' !! 'false'; }
    multi to-json($s) { die }

    # RAKUDO BUG #66596 (can't .subst in multis)
    sub string-to-json($d) {
        '"'
        ~ $d.trans(['"',  '\\',   "\b", "\f", "\n", "\r", "\t"]
                => ['\"', '\\\\', '\b', '\f', '\n', '\r', '\t'])\
             .subst(/<-[\c0..\c127]>/, { sprintf '\u%04x', ord(~$_) }, :g)
        ~ '"'
    }
}
# vim: ft=perl6
