=begin Pod

=head1 JSON::Tiny

C<JSON::Tiny> is a minimalistic module that reads and writes JSON.
It supports strings, numbers, arrays and hashes (no custom objects).

=head1 Synopsis

    use JSON::Tiny;
    my $json = to_json([1, 2, "a third item"]);
    my $original-data-structure = to-json($json);

=end Pod

module JSON::Tiny {
    use JSON::Tiny::Actions;
    use JSON::Tiny::Grammar;

    sub from_json($text) is export {
        my $a = JSON::Tiny::Actions.new();
        my $o = JSON::Tiny::Grammar.parse($text, :action($a));
        return $o.ast;
    }

    multi to_json(Num $d) is export { $d }
    multi to_json(Int $d) { $d }
    multi to_json(Str $d) { 
        '"'
        ~ $d
        ~ '"'
    }
    multi to_json(Array $data) {
        return  '[ ' 
               ~ (map { to_json($_) }, $data.values).join(', ')
               ~ ' ]';
    }
    multi to_json(Hash  $data) {
        return '{ '
               ~ (map { to_json(.key) ~ ' : ' ~ to_json(.value) }, $data.pairs).join(', ')
               ~ ' }';
    }
    multi to_json(Bool  $data) { $data ?? 'true' !! 'false'; }
    multi to_json($s) { die }
}
# vim: ft=perl6
