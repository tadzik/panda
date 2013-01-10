use Test;
use Panda::Installer;
use Panda::Resources;
use Shell::Command;

plan 10;

my $srcdir  = 'testmodules';
my $destdir = "{cwd}/removeme";

my $r = Panda::Resources.new(srcdir => $srcdir);
my $b = Panda::Installer.new(resources => $r, destdir => $destdir);

my $p = Pies::Project.new(name => 'compiled::module');

lives_ok { $b.install($p) };

sub file_exists_ok($a as Str, $msg as Str) {
    ok $a.IO ~~ :f, $msg
}

file_exists_ok "$destdir/lib/foo.pm", 'module installed';
file_exists_ok "$destdir/lib/foo.pir", 'pir installed';
file_exists_ok "$destdir/lib/bar.pod", 'pod installed';
file_exists_ok "$destdir/lib/baz.js", 'random files installed';
file_exists_ok "$destdir/bin/bar", 'bin installed';
ok "$destdir/.git".IO !~~ :e, 'git files not copied';
file_exists_ok "$destdir/compiled/module/doc/foofile",
               'docs installed 1';
file_exists_ok "$destdir/compiled/module/doc/bardir/barfile",
               'docs installed 2';

rm_rf $destdir;

my @lib = <foo.pm foo.pir bam.pir bam.pm blaz.pm blaz.pir shazam.js>;
my @order = $b.sort-lib-contents(@lib);
is_deeply @order,
          [<foo.pm bam.pm blaz.pm shazam.js foo.pir bam.pir blaz.pir>],
          'pirs will get installed after rest of the things';

# vim: ft=perl6
