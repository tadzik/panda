# Hacking, commiting and contributing guide

## Incompatible changes

If you're about to introduce a change that only works on some version of
Rakudo (or higher), there is no need to handle backwards compatibility
in code. We're worry about that after christmas, orelse in post-beta
state of Perl 6. Right now it's enough to tag the previous commit with
the last Rakudo release that doesn't have what you need, and then we
declare that users of such old version can use Panda no newer than
the one with a matching tag.
