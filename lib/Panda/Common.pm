module Panda::Common;
use Shell::Command;

sub dirname ($mod as Str) is export {
    $mod.subst(':', '_', :g);
}

sub indir (Str $where, Callable $what) is export {
    my $old = cwd;
    mkpath $where;
    chdir $where;
    my $fail;
    try { $what() }
    chdir $old;
    $!.throw if $!;
}

# vim: ft=perl6
