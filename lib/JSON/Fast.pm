use nqp;

module JSON::Fast;

#proto to-json is export {*}

#proto to-json($) is export {*}

#multi to-json(Real:D $d) { ~$d }
#multi to-json(Bool:D $d) { $d ?? 'true' !! 'false'; }
#multi to-json(Str:D  $d) {
    #'"'
    #~ $d.trans(['"',  '\\',   "\b", "\f", "\n", "\r", "\t"]
            #=> ['\"', '\\\\', '\b', '\f', '\n', '\r', '\t'])\
            #.subst(/<-[\c32..\c126]>/, { ord(~$_).fmt('\u%04x') }, :g)
    #~ '"'
#}
#multi to-json(Positional:D $d) {
    #return  '[ '
            #~ $d.map(&to-json).join(', ')
            #~ ' ]';
#}
#multi to-json(Associative:D  $d) {
    #return '{ '
            #~ $d.map({ to-json(.key) ~ ' : ' ~ to-json(.value) }).join(', ')
            #~ ' }';
#}

#multi to-json(Mu:U $) { 'null' }
#multi to-json(Mu:D $s) {
    #die "Can't serialize an object of type " ~ $s.WHAT.perl
#}

my sub nom-ws(str $text, int $pos is rw) {
    while (my int $ord = nqp::ordat($text, $pos)) and ($ord == 32 || $ord == 10 || $ord == 13 || $ord == 9) {
        $pos = $pos + 1;
    }
}

my sub parse-string(str $text, int $pos is rw) {
    # fast-path a search through the string for the first "special" character ...
    my int $startpos = $pos;

    my str $result;

    loop {
        my int $ord = nqp::ordat($text, $pos);
        $pos = $pos + 1;

        if $ord == 34 { # "
            $result = nqp::substr($text, $startpos, $pos - 1 - $startpos);
            last;
        } elsif $ord == 92 { # \
            die "backslash sequences NYI";
            #$result = substr($text, $startpos, $pos - $startpos);
            #loop {
                
            #}
        }
    }

    $result;
}

my sub parse-numeric(str $text, int $pos is rw) {
    my int $startpos = $pos;

    $pos = $pos + 1 while nqp::iscclass(nqp::const::CCLASS_NUMERIC, $text, $pos);

    my str $residual = nqp::substr($text, $pos, 1);

    if $residual eq '.' {
        $pos = $pos + 1;

        $pos = $pos + 1 while nqp::iscclass(nqp::const::CCLASS_NUMERIC, $text, $pos);

        $residual = nqp::substr($text, $pos, 1);
    }
    
    if $residual eq 'e' || $residual eq 'E' {
        $pos = $pos + 1;

        if nqp::eqat($text, '-', $pos) || nqp::eqat($text, '+', $pos) {
            $pos = $pos + 1;
        }

        $pos = $pos + 1 while nqp::iscclass(nqp::const::CCLASS_NUMERIC, $text, $pos);
    }

    +nqp::substr($text, $startpos - 1, $pos - $startpos);
}

my sub parse-null(str $text, int $pos is rw) {
    if nqp::eqat($text, 'ull', $pos) {
        $pos += 3;
        Any;
    } else {
        die "i was expecting a 'null' at $pos, but there wasn't one: { nqp::substr($text, $pos - 1, 10) }"
    }
}


my sub parse-obj(str $text, int $pos is rw) {
    my %result;

    my $key;
    my $value;

    nom-ws($text, $pos);

    if nqp::eqat($text, '}', $pos) {
        $pos = $pos + 1;
        %();
    } else {
        loop {
            my $thing = parse-thing($text, $pos);
            nom-ws($text, $pos);

            my str $partitioner = nqp::substr($text, $pos, 1);
            $pos = $pos + 1;

            if $partitioner eq ':'      and not defined $key and not defined $value {
                $key = $thing;
            } elsif $partitioner eq ',' and     defined $key and not defined $value {
                $value = $thing;

                %result{$key} = $value;

                $key   = Nil;
                $value = Nil;
            } elsif $partitioner eq '}' and     defined $key and not defined $value {
                $value = $thing;

                %result{$key} = $value;
                last;
            } else {
                die "unexpected $partitioner in an object at $pos";
            }
        }

        %result;
    }
}

my sub parse-array(str $text, int $pos is rw) {
    my @result;

    nom-ws($text, $pos);

    if nqp::eqat($text, ']', $pos) {
        $pos = $pos + 1;
        [];
    } else {
        loop {
            my $thing = parse-thing($text, $pos);
            nom-ws($text, $pos);

            my str $partitioner = nqp::substr($text, $pos, 1);
            $pos = $pos + 1;

            if $partitioner eq ']' {
                @result.push: $thing;
                last;
            } elsif $partitioner eq "," {
                @result.push: $thing;
            } else {
                die "unexpected $partitioner inside list of things in an array";
            }
        }
        @result;
    }
}

my sub parse-thing(str $text, int $pos is rw) {
    nom-ws($text, $pos);

    my str $initial = nqp::substr($text, $pos, 1);

    $pos = $pos + 1;

    if $initial eq '"' {
        parse-string($text, $pos);
    } elsif $initial eq '[' {
        parse-array($text, $pos);
    } elsif $initial eq '{' {
        parse-obj($text, $pos);
    } elsif nqp::iscclass(nqp::const::CCLASS_NUMERIC, $initial, 0) || $initial eq '-' {
        parse-numeric($text, $pos);
    } elsif $initial eq 'n' {
        parse-null($text, $pos);
    } elsif $initial eq 't' {
        if nqp::eqat($text, 'rue', $pos) {
            $pos = $pos + 3;
            True
        }
    } elsif $initial eq 'f' {
        if nqp::eqat($text, 'alse', $pos) {
            $pos = $pos + 4;
            True
        }
    } else {
        die "can't parse objects starting in $initial yet."
    }
}

sub from-json(Str() $text) is export {
    my str $ntext = $text;
    my int $length = $text.chars;

    my int $pos = 0;

    nom-ws($text, $pos);

    my str $initial = nqp::substr($text, $pos, 1);

    $pos = $pos + 1;

    if $initial eq '{' {
        parse-obj($ntext, $pos);
    } elsif $initial eq '[' {
        parse-array($ntext, $pos);
    }
}
