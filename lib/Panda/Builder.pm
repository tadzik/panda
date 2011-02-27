use Pies;
use Panda::Common;

class Panda::Builder does Pies::Builder {
    has $!srcdir;

    method build(Pies::Project $p) {
        indir "$!srcdir/{dirname $p.name}", {
            run 'ufo' and die "ufo failed";
            run 'make' and die "Building failed";
        };
    }
}

# vim: ft=perl6
