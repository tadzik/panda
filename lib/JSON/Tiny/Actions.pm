class JSON::Tiny::Actions;

method TOP($/, $what) { 
    make $/{$what}.ast;
};
method object($/) {
    make hash ( $<pairlist>.ast );
}

method pairlist($/) {
    my %r;
    for $<pair>.map({$_.ast}) -> $m {
        %r{$m<key>} = $m<value>;
    }
    make %r;
}

method pair($/) {
    make {
        key => $<string>.ast,
        value => $<value>.ast,
    };
}

method array($/) {
    if $<value> {
        make [ $<value>.map: *.ast ];
    } else {
        make [];
    }
}

method value($/, $what) {
    given $what {
        when 'true'     { make Bool::True  };
        when 'false'    { make Bool::False };
        when 'null'     { make undef       };
        when *          { make $/{$_}.ast  };
    }
}

method string($/) {
    my $s = '';
    for $0.chunks {
        if .key eq '~' {
            $s ~= .value;
        } else {
            say $_.perl;
            $s ~= .value.<str_escape>.ast;
            say "alive";
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
#    say "In str_escape(): ", $/.ast.perl;
}

method number($/) {
    make +$/;
}

# vim: ft=perl6
