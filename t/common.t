use v6;
use Test;
use Panda::Common;

plan 2;
my $cwd = cwd;

dies_ok { indir 't', { die "OH NOEZ" } }, '&indir passes exceptions on';
is cwd(), $cwd, 'indir rewinds cwd even when exceptions were thrown';
