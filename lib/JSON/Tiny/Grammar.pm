use v6;
grammar JSON::Tiny::Grammar;

rule TOP        { ^[ <object> | <array> ]$ }
rule object     { '{' ~ '}' <pairlist>     }
rule pairlist   { [ <pair> ** [ \, ]  ]?   }
rule pair       { <string> ':' <value>     }
rule array      { '[' ~ ']' [ <value> ** [ \, ] ]?  }

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

token string {
    \" ~ \" [ <str> | \\ <str_escape> ]*
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
    <["\\/bfnrt]> | u <xdigit>**4
}

# vim: ft=perl6
