use v6;
BEGIN { @*INC.push('lib') };

use JSON::Tiny::Grammar;
use Test;

my @t = 
    '{  }',
    '{ "a" : "b" }',
    '{ "a" : null }',
    '{ "a" : true }',
    '{ "a" : false }',
    '{ "a" : { } }',
    # stolen from JSON::XS, 18_json_checker.t, and adapted a bit
    Q<<[
    "JSON Test Pattern pass1",
    {"object with 1 member":["array with 1 element"]},
    {},
    []
    ]>>,
    Q<<[-42,true,false,null]>>,
    Q<<{ "integer": 1234567890 }>>,
    Q<<{ "real": -9876.543210 }>>,
    Q<<{ "e": 0.123456789e-12 }>>,
    Q<<{ "E": 1.234567890E+34 }>>,
    Q<<{ "":  23456789012E66 }>>,
    Q<<{ "zero": 0 }>>,
    Q<<{ "one": 1 }>>,
    Q<<{ "space": " " }>>,
    Q<<{ "quote": "\""}>>,
    Q<<{ "backslash": "\\"}>>,
    Q<<{ "controls": "\b\f\n\r\t"}>>,
    Q<<{ "slash": "/ & \/"}>>,
    Q<<{ "alpha": "abcdefghijklmnopqrstuvwyz"}>>,
    Q<<{ "ALPHA": "ABCDEFGHIJKLMNOPQRSTUVWYZ"}>>,
    Q<<{ "digit": "0123456789"}>>,
    Q<<{ "0123456789": "digit"}>>,
    Q<<{"special": "`1~!@#$%^&*()_+-={':[,]}|;.</>?"}>>,
    Q<<{"hex": "\u0123\u4567\u89AB\uCDEF\uabcd\uef4A"}>>,
    Q<<{"true": true}>>,
    Q<<{"false": false}>>,
    Q<<{"null": null}>>,
    Q<<{"array":[  ]}>>,
    Q<<{"object":{  }}>>,
    Q<<{"address": "50 St. James Street"}>>,
    Q<<{"url": "http://www.JSON.org/"}>>,
    Q<<{"comment": "// /* <!-- --"}>>,
    Q<<{"# -- --> */": " "}>>,
    Q<<{ " s p a c e d " :[1,2 , 3

,

4 , 5        ,          6           ,7        ],"compact":[1,2,3,4,5,6,7]}>>,

    Q<<{"jsontext": "{\"object with 1 member\":[\"array with 1 element\"]}"}>>,
    Q<<{"quotes": "&#34; \u0022 %22 0x22 034 &#x22;"}>>,
    Q<<{    "\/\\\"\uCAFE\uBABE\uAB98\uFCDE\ubcda\uef4A\b\f\n\r\t`1~!@#$%^&*()_+-=[]{}|;:',./<>?"
: "A key can be any string"
    }>>,
    Q<<[    0.5 ,98.6
,
99.44
,

1066,
1e1,
0.1e1
    ]>>,
    Q<<[1e-1]>>,
    Q<<[1e00,2e+00,2e-00,"rosebud"]>>,
    Q<<[[[[[[[[[[[[[[[[[[["Not too deep"]]]]]]]]]]]]]]]]]]]>>,
    Q<<{
    "JSON Test Pattern pass3": {
        "The outermost value": "must be an object or array.",
        "In this test": "It is an object."
    }
}
>>,
    ;

my @n = 
    '{ ',
    '{ 3 : 4 }',
    '{ 3 : tru }',  # not quite true
    '{ "a : false }', # missing quote
    # stolen from JSON::XS, 18_json_checker.t
    Q<<"A JSON payload should be an object or array, not a string.">>,
    Q<<{"Extra value after close": true} "misplaced quoted value">>,
    Q<<{"Illegal expression": 1 + 2}>>,
    Q<<{"Illegal invocation": alert()}>>,
    Q<<{"Numbers cannot have leading zeroes": 013}>>,
    Q<<{"Numbers cannot be hex": 0x14}>>,
    Q<<["Illegal backslash escape: \x15"]>>,
    Q<<[\naked]>>,
    Q<<["Illegal backslash escape: \017"]>>,
    Q<<[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[["Too deep"]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]>>,
    Q<<{"Missing colon" null}>>,
    Q<<["Unclosed array">>,
    Q<<{"Double colon":: null}>>,
    Q<<{"Comma instead of colon", null}>>,
    Q<<["Colon instead of comma": false]>>,
    Q<<["Bad value", truth]>>,
    Q<<['single quote']>>,
    Q<<["	tab	character	in	string	"]>>,
    Q<<["tab\   character\   in\  string\  "]>>,
    Q<<["line
break"]>>,
    Q<<["line\
break"]>>,
    Q<<[0e]>>,
    Q<<{unquoted_key: "keys must be quoted"}>>,
    Q<<[0e+]>>,
    Q<<[0e+-1]>>,
    Q<<{"Comma instead if closing brace": true,>>,
    Q<<["mismatch"}>>,
    Q<<["extra comma",]>>,
    Q<<["double extra comma",,]>>,
    Q<<[   , "<-- missing value"]>>,
    Q<<["Comma after the close"],>>,
    Q<<["Extra close"]]>>,
    Q<<{"Extra comma": true,}>>,
;

plan (+@t) + (+@n);

my $i = 0;
for @t -> $t {
    my $desc = $t;
    if $desc ~~ m/\n/ {
        $desc .= subst(/\n.*$/, "\\n...[$i]");
    }
    ok JSON::Tiny::Grammar.parse($t), "JSON string «$desc» parsed";
    $i++;
}

for @n -> $t {
    ok (try { JSON::Tiny::Grammar.parse($t) }) ~~ undef, "NOT parsed «$t»";

}


# vim: ft=perl6

