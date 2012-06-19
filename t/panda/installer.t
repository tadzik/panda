use Test;
use Panda::Installer;
use Panda::Resources;

plan 7;

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
file_exists_ok "$destdir/bin/bar", 'bin installed';
file_exists_ok "$destdir/compiled/module/doc/foofile",
               'docs installed 1';
file_exists_ok "$destdir/compiled/module/doc/bardir/barfile",
               'docs installed 2';

shell "rm -rf $destdir";

# vim: ft=perl6
