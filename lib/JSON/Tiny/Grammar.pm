use v6;
grammar JSON::Tiny::Grammar {
    rule TOP { 
        ^ [
            | <object> {*}      #= object
            | <array>  {*}      #= array
        ]$ };
    rule object     { '{' ~ '}' <pairlist>      {*}   };
    rule pairlist   {
        [ <pair>
         [\, [ <pair> | <.fail_trailing> ] ]*
        ]?
        {*}
    };

    rule pair {
        <string> ':' <value>        {*}
    };

    rule array {
        '[' ~ ']'
            [   # work around non-existing LTM
                [
                    <value>**1
                    [\, [<value> | <.fail_trailing>] ]*
                ]?
                \s*
            ]
        {*}
    };

    rule value {
        | <string>  {*}     #= string
        | <number>  {*}     #= number
        | <object>  {*}     #= object
        | <array>   {*}     #= array
        | 'true'    {*}     #= true
        | 'false'   {*}     #= false
        | 'null'    {*}     #= null
    };

    token string {
        \" ~ \" ([
            | <-["\\\t\n]>
            | \\ <str_escape>
        ]*) {*}
    };

    token str_escape {
         <["\\/bfnrt]>
        | u <xdigit>**4 
    };

    token number {
        \- ?
        [ 0 | <[1..9]> <[0..9]>* ]
        [ \. <[0..9]>+ ]?
        [ <[eE]> [\+|\-]? <[0..9]>+ ]?
        {*}
    }

    regex fail_trailing {
        <fail: 'Expecting value after comma (trailing comma?)'>
    }
}

# vim: ft=perl6
