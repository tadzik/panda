# JSON::Fast

a naive imperative json parser in pure perl6 (but with direct access to nqp:: ops), to evaluate performance against JSON::Tiny. It is a drop-in replacement for JSON::Tiny's from-json sub.

Currently it seems to be about 5x faster and uses up about a fourth of the RAM.

There should be some more speed attainable through tuning, micro-optimizations, re-introducing the block flattening optimization in rakudo and other stuff.

This module also includes a very fast to-json function that tony-o created in tony-o/perl6-json-faster.

# Exported subroutines

## `to-json`

```perl6
    say to-json [<my Perl data structure>];
    say to-json [<my Perl data structure>], :!pretty;
    say to-json [<my Perl data structure>], :spacing(4);
```

Encode a Perl data structure into JSON. Takes one positional argument, which
is a thing you want to encode into JSON. Takes these optional named arguments:

### `pretty`

`Bool`. Defaults to `True`. Specifies whether the output should be "pretty",
human-readable JSON.

### `spacing`

`Int`. Defaults to `2`. Applies only when [`pretty`](#pretty) is `True`.
Controls how much spacing there is between each nested level of the output.

## `from-json`

```perl6
    my $x = from-json '["foo", "bar", {"ber": "bor"}]';
    say $x.perl;
    # outputs: $["foo", "bar", {:ber("bor")}]
```
Takes one positional argument that is coerced into a `Str` type and represents
a JSON text to decode. Returns a Perl datastructure representing that JSON.
