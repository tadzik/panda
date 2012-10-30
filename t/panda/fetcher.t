use Test;
use Panda::Fetcher;
use Panda::Resources;
use Shell::Command;

plan 3;

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

$p.metainfo<source-type> = 'hg';
try { $f.fetch($p) }
ok $! ~~ /'hg not supported'/, 'checks source-type';

$p.metainfo<source-type> = 'local';
$p.metainfo<source-url>  = 'testmodules/dummymodule';

lives_ok { $f.fetch($p) }, 'can fetch a local project';
ok "$srcdir/foobar/lib/foo.pm".IO ~~ :f, 'fetch ok';

rm_rf $srcdir;

# vim: ft=perl6
