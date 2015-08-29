use v6;

use JSON::Fast;
use Test;

my @t =
   '{ "a" : 1 }' => { a => 1 },
   '[]'          => [],
   '{}'          => {},
   '[ "a", "b"]' => [ "a", "b" ],
   '[3]'         => [3],
   '["\t\n"]'    => ["\t\n"],
   '["\""]'      => ['"'],
   '[{ "foo" : { "bar" : 3 } }, 78]' => [{ foo => { bar => 3 }}, 78],
   '[{ "a" : 3, "b" : 4 }]' => [{ a => 3, b => 4},],
    Q<<{
    "glossary": {
        "title": "example glossary",
		"GlossDiv": {
            "title": "S",
			"GlossList": {
                "GlossEntry": {
                    "ID": "SGML",
					"SortAs": "SGML",
					"GlossTerm": "Standard Generalized Markup Language",
					"Acronym": "SGML",
					"Abbrev": "ISO 8879:1986",
					"GlossDef": {
                        "para": "A meta-markup language, used to create markup languages such as DocBook.",
						"GlossSeeAlso": ["GML", "XML"]
                    },
					"GlossSee": "markup"
                }
            }
        }
    }
}
    >> => {
    "glossary" => {
        "title" => "example glossary",
		"GlossDiv" => {
            "title" => "S",
			"GlossList" => {
                "GlossEntry" => {
                    "ID" => "SGML",
					"SortAs" => "SGML",
					"GlossTerm" => "Standard Generalized Markup Language",
					"Acronym" => "SGML",
					"Abbrev" => "ISO 8879:1986",
					"GlossDef" => {
                        "para" => "A meta-markup language, used to create markup languages such as DocBook.",
						"GlossSeeAlso" => ["GML", "XML"]
                    },
					"GlossSee" => "markup"
                }
            }
        }
    }
},
;
plan +@t;

for @t -> $p {
    my $s = try from-json($p.key);
    is-deeply $s, $p.value,
        "Correct data structure for «{$p.key.subst(/\n/, '\n', :g)}»";
}

# vim: ft=perl6
