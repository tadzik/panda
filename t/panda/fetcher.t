use Test;
use Panda::Fetcher;
use Panda::Resources;

plan 4;

my $srcdir = 'REMOVEME';
my $r = Panda::Resources.new(srcdir => $srcdir);
my $f = Panda::Fetcher.new(resources => $r);

my $p = Pies::Project.new(
    name     => 'foobar',
    version  => 0,
    metainfo => {
        source-type => 'git',
        source-url  => 't/',
    }
);

try { $f.fetch($p) }
ok $! ~~ /'Failed cloning'/, 'attempts to clone';

$p.metainfo<source-type> = 'hg';
try { $f.fetch($p) }
ok $! ~~ /'hg not supported'/, 'checks source-type';

$p.metainfo<source-type> = 'local';
$p.metainfo<source-url>  = 'testmodules/dummymodule';

lives_ok { $f.fetch($p) }, 'can fetch a local project';
ok "$srcdir/foobar/lib/foo.pm".IO ~~ :f, 'fetch ok';

shell "rm -r $srcdir";

# vim: ft=perl6
