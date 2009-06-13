use v6;
BEGIN { @*INC.push('lib') };
use JSON::Tiny::Grammar;
use JSON::Tiny::Actions;
use Test;

my @t = 
   '{ "a" : 1 }' => { a => 1 },
   '[]'          => [],
   '{}'          => {},
   '[ "a", "b"]' => [ "a", "b" ],
   '[3]'         => [3],
   '["\t\n"]'    => ["\t\n"],
   '[{ "foo" : { "bar" : 3 } }, 78]' => [{ foo => { bar => 3 }}, 78],
   '[{ "a" : 3, "b" : 4 }]' => [{ a => 3, b => 4}],
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
    my $a = JSON::Tiny::Actions.new();
    my $o = JSON::Tiny::Grammar.parse($p.key, :action($a));
    is_deeply $o.ast, $p.value, "Correct data structure for «{$p.key}»"
        or say "# Got: {$o.ast.perl}\n# Expected: {$p.value.perl}";
}

# vim: ft=perl6
