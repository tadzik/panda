use v6;

use Test;
use lib 'lib';
use File::Which;

my @execs = ('calc', 'cmd', 'explorer', 'iexplore', 'wordpad', 'notepad');

plan @execs.elems * 2;

unless $*DISTRO.is-win {
  skip-rest("Windows-only tests");
  exit;
}

for @execs -> $exec {
  my Str $path = which($exec);
  ok $path.defined, sprintf("Found '%s' at '%s'", $exec, $path);
  ok $path.IO ~~ :e, sprintf("Path '%s' is found", $path);
}
