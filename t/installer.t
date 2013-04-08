use Test;
use Panda::Installer;
use Shell::Command;

plan 8;

my $src  = 'testmodules/compiled__module';
my $dest = "{cwd}/removeme";

lives_ok { Panda::Installer.install($src, $dest) };

sub file_exists_ok($a as Str, $msg as Str) {
    ok $a.IO ~~ :f, $msg
}

file_exists_ok "$dest/lib/foo.pm", 'module installed';
file_exists_ok "$dest/lib/foo.pir", 'pir installed';
file_exists_ok "$dest/lib/bar.pod", 'pod installed';
file_exists_ok "$dest/lib/baz.js", 'random files installed';
file_exists_ok "$dest/bin/bar", 'bin installed';
ok "$dest/.git".IO !~~ :e, 'git files not copied';

rm_rf $dest;

my @lib = <foo.pm foo.pir bam.pir bam.pm blaz.pm blaz.pir shazam.js>;
my @order = Panda::Installer.sort-lib-contents(@lib);
is_deeply @order,
          [<foo.pm bam.pm blaz.pm shazam.js foo.pir bam.pir blaz.pir>],
          'pirs will get installed after rest of the things';

# vim: ft=perl6
