module JSON::Fast;

proto to-json is export {*}

proto to-json($) is export {*}

multi to-json(Real:D $d) { ~$d }
multi to-json(Bool:D $d) { $d ?? 'true' !! 'false'; }
multi to-json(Str:D  $d) {
    '"'
    ~ $d.trans(['"',  '\\',   "\b", "\f", "\n", "\r", "\t"]
            => ['\"', '\\\\', '\b', '\f', '\n', '\r', '\t'])\
            .subst(/<-[\c32..\c126]>/, { ord(~$_).fmt('\u%04x') }, :g)
    ~ '"'
}
multi to-json(Positional:D $d) {
    return  '[ '
            ~ $d.map(&to-json).join(', ')
            ~ ' ]';
}
multi to-json(Associative:D  $d) {
    return '{ '
            ~ $d.map({ to-json(.key) ~ ' : ' ~ to-json(.value) }).join(', ')
            ~ ' }';
}

multi to-json(Mu:U $) { 'null' }
multi to-json(Mu:D $s) {
    die "Can't serialize an object of type " ~ $s.WHAT.perl
}



sub from-json($text) is export {

}
