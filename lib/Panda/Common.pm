module Panda::Common;
use File::Mkdir;

sub dirname ($mod as Str) is export {
    $mod.subst(':', '_', :g);
}

sub indir (Str $where, Callable $what) is export {
    my $old = cwd;
    mkdir $where, :p;
    chdir $where;
    my $fail;
    try { $what(); CATCH { $fail = $! } }
    chdir $old;
    die $fail if $fail;
}

# vim: ft=perl6
