use Pies;
use Panda::Common;

class Panda::Installer does Pies::Installer {
    has $!srcdir;
    has $!destdir;

    method install(Pies::Project $p) {
        indir "$!srcdir/{dirname $p.name}", {
            unless 'Makefile'.IO ~~ :f {
                run 'ufo' and die 'ufo failed';
            }
            my $infix = $!destdir ?? "PREFIX=$!destdir" !! '';
            run "make $infix install" and die "Installing failed";
        };
    }
}

# vim: ft=perl6
