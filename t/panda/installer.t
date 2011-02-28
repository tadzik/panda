use Test;
use Panda::Installer;

plan 2;

my $srcdir  = 'testmodules';
my $destdir = "{cwd}/removeme";

my $b = Panda::Installer.new(srcdir => $srcdir, destdir => $destdir);

my $p = Pies::Project.new(name => 'dummymodule');

lives_ok { $b.install($p) };

ok "$destdir/lib/foo.pm".IO ~~ :f, 'module installed';

run "rm -rf $destdir";

# vim: ft=perl6
