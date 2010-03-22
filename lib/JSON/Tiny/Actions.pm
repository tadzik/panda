class JSON::Tiny::Actions;

method TOP($/, $what) {
    make $/{$what}.ast;
};
method object($/) {
    make %( $<pairlist>.ast );
}

method pairlist($/) {
    if $<pair> {
        make $<pair>>>.ast;
    }
    else {
        make ();
    }
}

method pair($/) {
    make ( $<string>.ast => $<value>.ast );
}

method array($/) {
    if $<value> {
        make $<value>>>.ast;
    } else {
        make [];
    }
}

method value($/, $what) {
    given $what {
        when 'true'     { make Bool::True  };
        when 'false'    { make Bool::False };
        when 'null'     { make Any         };
        when *          { make $/{$_}.ast  };
    }
}

method string($/) {
    my $s = '';
    for $0.chunks {
        if .key eq '~' {
            if .value eq '\\' { next }
            $s ~= .value;
        } else {
            $s ~= .value.ast;
        }
    }
    make $s;
}

method str_escape($/) {
    if $<xdigit> {
        make chr(:16($<xdigit>.join));
    } else {
        given ~$/ {
            when '\\' { make '\\'; }
            when 'n'  { make "\n"; }
            when 't'  { make "\t"; }
            when 'f'  { make "\f"; }
            when 'r'  { make "\r"; }
        }
    }
}

method number($/) {
    make +$/;
}

# vim: ft=perl6
