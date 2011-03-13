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
        repo-type => 'git',
        repo-url  => 't/',
    }
);

try { $f.fetch($p) }
ok $! ~~ /'Failed cloning'/, 'attempts to clone';

$p.metainfo<repo-type> = 'hg';
try { $f.fetch($p) }
ok $! ~~ /'hg not supported'/, 'checks repo-type';

$p.metainfo<repo-type> = 'local';
$p.metainfo<repo-url>  = 'testmodules/dummymodule';

lives_ok { $f.fetch($p) }, 'can fetch a local project';
ok "$srcdir/foobar/lib/foo.pm".IO ~~ :f, 'fetch ok';

run "rm -r $srcdir";

# vim: ft=perl6
