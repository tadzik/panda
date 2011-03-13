use Test;
use Panda::Fetcher;
use Panda::Resources;

plan 2;

my $r = Panda::Resources.new(srcdir => '/tmp/whatever');
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
ok $! ~~ /'other than git'/, 'checks repo-type';

# vim: ft=perl6
