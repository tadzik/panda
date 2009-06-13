class JSON::Tiny::Actions;

method TOP($/, $what) { 
    make $/{$what}.ast;
};
method object($/) {
    make ~$<pairlist> ?? hash ( $<pairlist>.ast ) !! {};
}

method pairlist($/) {
    if $<pair> {
        my %r;
        for $<pair>.map({$_.ast}) -> $m {
            %r{$m<key>} = $m<value>;
        }
        make %r;
    }
    else {
        make undef;
    }
}

method pair($/) {
    make {
        key => $<string>.ast,
        value => $<value>.ast,
    };
}

method array($/) {
    if $<value> {
        my @r = ();
        for $<value>>>.ast {
            when Hash { @r.push: \$_ }
            default   { @r.push:  $_ }
        }
        make @r
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
            next if .value eq '\\'; #'
            $s ~= .value;
        } else {
            $s ~= ~(.value.ast);
        }
    }
    make $s;
}

method str_escape($/) {
    if $<xdigit> {
        make chr(:16($<xdigit>.join));
    } else {
        given ~$/ {
            when '\\' { make '\\'; } #'
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
