use v6;
grammar JSON::Tiny::Grammar;
rule TOP {
    ^ [
        | <object>
        | <array>
    ]$
}
rule object     { '{' ~ '}' <pairlist> }
rule pairlist   {
    [ <pair>
        # JSON doesn't allow trailing commas in lists,
        # even though Javascript does. Since this causes
        # lots of Perl hackers by surprise, throw a designated
        # error mesasge in that case
        [\, [ <pair> || <.fail_trailing> ] ]*
    ]?
    {*}
}

rule pair {
    <string> ':' <value>
}

rule array {
    '[' ~ ']'
        [   # work around non-existing LTM
            [
                <value>**1
                [\, [<value> || <.fail_trailing>] ]*
            ]?
            \s*
        ]
    {*}
}


proto token value { <...> };
token value:sym<number> {
    '-'?
    [ 0 | <[1..9]> <[0..9]>* ]
    [ \. <[0..9]>+ ]?
    [ <[eE]> [\+|\-]? <[0..9]>+ ]?
}
token value:sym<true>    { <sym>    };
token value:sym<false>   { <sym>    };
token value:sym<null>    { <sym>    };
token value:sym<object>  { <object> };
token value:sym<array>   { <array>  };
token value:sym<string>  { <string> }

rule string {
    <.ws>
    \" ~ \" ([
        | <str>
        | \\ <str_escape>
    ]*)
    <.ws>
}

token str {
    [
        <!before \t>
        <!before \n>
        <!before \\>
        <!before \">
        .
    ]+
#    <-["\\\t\n]>+
}

token str_escape {
    [
        <["\\/bfnrt]>
    | u <xdigit>**4
    ] {*}
}

regex fail_trailing {
    <panic: 'Expecting value after comma (trailing comma?)'>
}

# vim: ft=perl6
