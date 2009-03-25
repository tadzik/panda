class JSON::Tiny::Actions;

method TOP($/, $what) { 
    make $/{$what}.ast;
};
method object($/) {
    make $<pairlist>.ast;
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

method value($/, $what) {
#    do { do { make 1 } };
    when * { make 1 } ;

#    given $what {
#        when 'true'     { make Bool::True  };
#        when 'false'    { make Bool::False };
#        when 'null'     { make undef       };
#        when *          { make 2           };
##        when *          { make $/{$_}.ast  };
#    }
}

# vim: ft=perl6
