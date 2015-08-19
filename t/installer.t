use Test;
use Panda::Common;
use Panda::Installer;
use Shell::Command;

plan 8;

my $src  = 'testmodules/compiled__module';
my $dest = "$*CWD/removeme";

lives-ok { Panda::Installer.install($src, $dest) };

sub file_exists_ok($a as Str, $msg as Str) {
    ok $a.IO ~~ :f, $msg
}

file_exists_ok "$dest/lib/foo.pm", 'module installed';
file_exists_ok "$dest/lib/foo.{compsuffix}",  "{compsuffix} installed";
file_exists_ok "$dest/lib/bar.pod", 'pod installed';
file_exists_ok "$dest/lib/baz.js", 'random files installed';
file_exists_ok "$dest/bin/bar", 'bin installed';
ok "$dest/.git".IO !~~ :e, 'git files not copied';

rm_rf $dest;

my @lib = 'foo.pm', 'foo.' ~ compsuffix, 'bam.' ~ compsuffix, 
          'bam.pm', 'blaz.pm', 'blaz.' ~ compsuffix, 'shazam.js';
my @order = Panda::Installer.sort-lib-contents(@lib);
is-deeply @order,
          [flat <foo.pm bam.pm blaz.pm shazam.js>,
          'foo.' ~ compsuffix, 'bam.' ~ compsuffix, 'blaz.' ~ compsuffix],
          "{compsuffix}s will get installed after rest of the things";

# vim: ft=perl6
