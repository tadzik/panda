use v6;
use Test;
use Panda::Common;

plan 2;
my $cwd = $*CWD;

dies-ok { indir 't', { die "OH NOEZ" } }, '&indir passes exceptions on';
is $*CWD, $cwd, 'indir rewinds cwd even when exceptions were thrown';
