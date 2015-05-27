use v6;
BEGIN { @*INC.push('lib') };

use JSON::Tiny;
use Test;

plan 2;

# U+1D4B7 MATHEMATICAL SCRIPT SMALL B, from the WHATWG HTML entities JSON file
my $surrogate-pair = '\uD835\uDCB7';
my $json = '{ "codepoints" :  [119991], "characters" :  "\uD835\uDCB7" }';
my $perl =  { 'codepoints' => [119991], 'characters' => '𝒷'            };

my $parsed = from-json($json);

is-deeply $parsed, $perl,
    "UTF-16 surrogate pair «$surrogate-pair» parses correctly";

my $serialised = to-json($parsed<characters>);

is $serialised.lc, '"' ~ $surrogate-pair.lc ~ '"',
    'Astral plane codepoint roundtrips back to original JSON string';
