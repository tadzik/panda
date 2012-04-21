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

class X::Panda is Exception {
    has $.module;
    has $.stage;
    has $.description;

    method new($module, $stage, $description) {
        self.bless(*, :$module, :$stage, :$description)
    }

    method message {
        sprintf "%s stage failed for %s: %s",
                $.stage, $.module, $.description
    }
}

# vim: ft=perl6
