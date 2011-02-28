use Pies;
use Panda::Common;

class Panda::Tester does Pies::Tester {
    has $!srcdir;

    method test(Pies::Project $p) {
        indir "$!srcdir/{dirname $p.name}", {
            if 't'.IO ~~ :d {
                unless 'Makefile'.IO ~~ :f {
                    run 'ufo' and die 'ufo failed';
                }
                run 'make test' and die "Testing failed";
            }
        };
    }
}

# vim: ft=perl6
