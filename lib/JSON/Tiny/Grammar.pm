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
         # JSON doesn't allow trailing commas in lists,
         # even though Javascript does. Since this causes
         # lots of Perl hackers by surprise, throw a designated
         # error mesasge in that case
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

    # TODO: turn into a proto regex once they are implemented
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
            | <str>
            | \\ <str_escape>
        ]*) {*}
    };

    token str {
        <-["\\\t\n]>+
    }

    token str_escape {
        [
         <["\\/bfnrt]>
        | u <xdigit>**4 
        ] {*}
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
