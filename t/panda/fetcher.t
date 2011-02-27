use Test;
use Panda::Ecosystem;
use Panda::Fetcher;

plan 2;

my $f = Panda::Fetcher.new(srcdir => '/tmp/whatever');

my $p = Pies::Project.new(
    name     => 'foobar',
    version  => 0,
    metainfo => {
        repo-type => 'git',
        repo-url  => 't/',
    }
);

try { $f.fetch($p) }
say $!;
ok $! ~~ /'Failed cloning'/, 'attempts to clone';

$p.metainfo<repo-type> = 'hg';
try { $f.fetch($p) }
ok $! ~~ /'other than git'/, 'checks repo-type';

# vim: ft=perl6
