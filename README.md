# json_fast

a naive imperative json parser in pure perl6 (but with direct access to nqp:: ops), to evaluate performance against JSON::Tiny. It is a drop-in replacement for JSON::Tiny's from-json sub.

Currently it seems to be about 5x faster and uses up about a fourth of the RAM.

There should be some more speed attainable through tuning, micro-optimizations, re-introducing the block flattening optimization in rakudo and other stuff.

This module also includes a very fast to-json function that tony-o created in tony-o/perl6-json-faster.
