module Panda::Common;
use Shell::Command;

sub dirname ($mod as Str) is export {
    $mod.subst(':', '_', :g);
}

sub indir ($where, Callable $what) is export {
    mkpath $where;
    temp $*CWD = chdir($where);
    $what()
}

sub withp6lib(&what) is export {
    my $oldp6lib = %*ENV<PERL6LIB>;
    LEAVE {
        if $oldp6lib.defined {
            %*ENV<PERL6LIB> = $oldp6lib;
        }
        else {
            %*ENV<PERL6LIB>:delete;
        }
    }
    my $sep = $*DISTRO.is-win ?? ';' !! ':';
    %*ENV<PERL6LIB> = join $sep,
        $*CWD ~ '/blib/lib',
        $*CWD ~ '/lib',
        %*ENV<PERL6LIB> // ();
    what();
}

sub compsuffix is export { state $ = $*VM.precomp-ext }

sub comptarget is export { state $ = $*VM.precomp-target }

class X::Panda is Exception {
    has $.module is rw;
    has $.stage;
    has $.description;

    method new($module, $stage, $description is copy) {
        if $description ~~ Failure {
            $description = $description.exception.message
        }
        self.bless(:$module, :$stage, :$description)
    }

    method message {
        sprintf "%s stage failed for %s: %s",
                $.stage, $.module, $.description
    }
}

# vim: ft=perl6
