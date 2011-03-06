use Test;
use Panda::Installer;

plan 4;

my $srcdir  = 'testmodules';
my $destdir = "{cwd}/removeme";

my $b = Panda::Installer.new(srcdir => $srcdir, destdir => $destdir);

my $p = Pies::Project.new(name => 'compiledmodule');

lives_ok { $b.install($p) };

ok "$destdir/lib/foo.pm".IO  ~~ :f, 'module installed';
ok "$destdir/lib/foo.pir".IO ~~ :f, 'pir installed';
ok "$destdir/bin/bar".IO     ~~ :f, 'bin installed';

run "rm -rf $destdir";

# vim: ft=perl6
