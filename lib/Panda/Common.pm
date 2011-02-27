module Panda::Common;
use File::Mkdir;

sub dirname ($mod as Str) is export {
    $mod.subst(':', '_', :g);
}

sub indir (Str $where, Callable $what) is export {
    my $old = cwd;
    mkdir $where, :p;
    chdir $where;
    $what();
    chdir $old;
}

# vim: ft=perl6
