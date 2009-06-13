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
