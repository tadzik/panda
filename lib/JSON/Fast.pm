use nqp;

unit module JSON::Fast;

sub str-escape(str $text) {
  return $text.subst(/'\\'/, '\\\\', :g)\ 
              .subst(/"\n"/, '\\n',  :g)\
              .subst(/"\r"/, '\\r',  :g)\
              .subst(/"\t"/, '\\t',  :g)\
              .subst(/'"'/,  '\\"',  :g);  
}

sub to-json($obj is copy, Bool :$pretty = True, Int :$level = 0, Int :$spacing = 2) is export {
    return $obj ?? 'true' !! 'false' if $obj ~~ Bool;
    return $obj.Str if $obj ~~ Int|Rat;
    return "\"{str-escape($obj)}\"" if $obj ~~ Str;

    if $obj ~~ Seq {
        $obj = $obj.cache
    }

    my int  $lvl  = $level;
    my Bool $arr  = $obj ~~ Positional;
    my str  $out ~= $arr ?? '[' !! '{';
    my $spacer   := sub {
        $out ~= "\n" ~ (' ' x $lvl*$spacing) if $pretty;
    };

    $lvl++;
    $spacer();
    if $arr {
        for @($obj) -> $i {
          $out ~= to-json($i, :level($level+1), :$spacing, :$pretty) ~ ',';
          $spacer();
        }
    }
    else {
        for $obj.keys -> $key {
            $out ~= "\"{$key ~~ Str ?? str-escape($key) !! $key}\": " ~ to-json($obj{$key}, :level($level+1), :$spacing, :$pretty) ~ ',';
            $spacer();
        }
    }
    $out .=subst(/',' \s* $/, '');
    $lvl--;
    $spacer();
    $out ~= $arr ?? ']' !! '}';
    return $out;
}

my sub nom-ws(str $text, int $pos is rw) {
    my int $wsord;
    STATEMENT_LIST(
        $wsord = nqp::ordat($text, $pos);
        last unless $wsord == 32 || $wsord == 10 || $wsord == 13 || $wsord == 9;
        $pos = $pos + 1;
    ) while True;
    CATCH {
        die "at $pos: reached the end of the string while looking for things";
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
            my @pieces;

            $result = substr($text, $startpos, $pos - 1 - $startpos);
            @pieces.push: $result;

            die "reached end of string while looking for end of quoted string." if $pos > nqp::chars($text);
            if nqp::eqat($text, '"', $pos) {
                @pieces.push: '"';
            } elsif nqp::eqat($text, '\\', $pos) {
                @pieces.push: '\\';
            } elsif nqp::eqat($text, '/', $pos) {
                @pieces.push: '/';
            } elsif nqp::eqat($text, 'b', $pos) {
                @pieces.push: "\b";
            } elsif nqp::eqat($text, 'f', $pos) {
                @pieces.push: chr(0x0c);
            } elsif nqp::eqat($text, 'n', $pos) {
                @pieces.push: "\n";
            } elsif nqp::eqat($text, 'r', $pos) {
                @pieces.push: "\r";
            } elsif nqp::eqat($text, 't', $pos) {
                @pieces.push: "\t";
            } elsif nqp::eqat($text, 'u', $pos) {
                my $hexstr := nqp::substr($text, $pos + 1, 4);
                if nqp::chars($hexstr) != 4 {
                    die "expected exactly four alnum digits after \\u";
                }
                @pieces.push: chr(:16($hexstr));
                $pos = $pos + 4;
            } else {
                die "at $pos: I don't understand the escape sequence \\{ nqp::substr($text, $pos, 1) }";
            }

            if nqp::eqat($text, '"', $pos + 1) {
                $result = $result ~ @pieces[1];
                $pos = $pos + 2;
                last;
            } else {
                $pos = $pos + 1;
                @pieces.push: parse-string($text, $pos);
                $result = @pieces.join("");
                last;
            }
        } elsif $ord < 14 && ($ord == 10 || $ord == 13 || $ord == 9) {
            die "at $pos: the only whitespace allowed in json strings are spaces";
        }
    }

    $result;
}

my sub parse-numeric(str $text, int $pos is rw) {
    my int $startpos = $pos;

    $pos = $pos + 1 while nqp::iscclass(nqp::const::CCLASS_NUMERIC, $text, $pos);

    my $residual := nqp::substr($text, $pos, 1);

    if $residual eq '.' {
        $pos = $pos + 1;

        $pos = $pos + 1 while nqp::iscclass(nqp::const::CCLASS_NUMERIC, $text, $pos);

        $residual := nqp::substr($text, $pos, 1);
    }
    
    if $residual eq 'e' || $residual eq 'E' {
        $pos = $pos + 1;

        if nqp::eqat($text, '-', $pos) || nqp::eqat($text, '+', $pos) {
            $pos = $pos + 1;
        }

        $pos = $pos + 1 while nqp::iscclass(nqp::const::CCLASS_NUMERIC, $text, $pos);
    }

    +(my $result := nqp::substr($text, $startpos - 1, $pos - $startpos + 1)) // die "at $pos: invalid number token $result.perl()";
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
            my $thing;

            if defined $key {
                $thing = parse-thing($text, $pos)
            } else {
                nom-ws($text, $pos);

                if nqp::eqat($text, '"', $pos) {
                    $pos = $pos + 1;
                    $thing = parse-string($text, $pos)
                } else {
                    die "at end of string: expected a quoted string for an object key" if $pos == nqp::chars($text);
                    die "at $pos: json requires object keys to be strings";
                }
            }
            nom-ws($text, $pos);

            #my str $partitioner = nqp::substr($text, $pos, 1);

            if nqp::eqat($text, ':', $pos)      and not defined $key and not defined $value {
                $key = $thing;
            } elsif nqp::eqat($text, ',', $pos) and     defined $key and not defined $value {
                $value = $thing;

                %result{$key} = $value;

                $key   = Nil;
                $value = Nil;
            } elsif nqp::eqat($text, '}', $pos) and     defined $key and not defined $value {
                $value = $thing;

                %result{$key} = $value;
                $pos = $pos + 1;
                last;
            } else {
                die "at end of string: unexpected end of object." if $pos == nqp::chars($text);
                die "unexpected { nqp::substr($text, $pos, 1) } in an object at $pos";
            }

            $pos = $pos + 1;
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
                die "at $pos, unexpected $partitioner inside list of things in an array";
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
        if nqp::eqat($text, 'ull', $pos) {
            $pos += 3;
            Any;
        } else {
            die "at $pos: i was expecting a 'null' but there wasn't one: { nqp::substr($text, $pos - 1, 10) }"
        }
    } elsif $initial eq 't' {
        if nqp::eqat($text, 'rue', $pos) {
            $pos = $pos + 3;
            True
        } else {
            die "at $pos: expected 'true', found { $initial ~ nqp::substr($text, $pos, 3) } instead.";
        }
    } elsif $initial eq 'f' {
        if nqp::eqat($text, 'alse', $pos) {
            $pos = $pos + 4;
            False
        } else {
            die "at $pos: expected 'false', found { $initial ~ nqp::substr($text, $pos, 4) } instead.";
        }
    } else {
        my str $rest = nqp::substr($text, $pos, 6);
        die "at $pos: can't parse objects starting in $initial yet (context: $rest)"
    }
}

sub from-json(Str() $text) is export {
    my str $ntext = $text;
    my int $length = $text.chars;

    my int $pos = 0;

    nom-ws($text, $pos);

    my str $initial = nqp::substr($text, $pos, 1);

    $pos = $pos + 1;

    my $result;

    if $initial eq '{' {
        $result = parse-obj($ntext, $pos);
    } elsif $initial eq '[' {
        $result = parse-array($ntext, $pos);
    } else {
        die "a JSON string ought to be a list or an object";
    }

    try nom-ws($text, $pos);

    if $pos != nqp::chars($text) {
        die "additional text after the end of the document: { substr($text, $pos).perl }";
    }

    $result;
}

# vi:syntax=perl6
