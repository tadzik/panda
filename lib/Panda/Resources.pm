use Pies;

class Panda::Resources {
    has $.srcdir;
    method workdir(Pies::Project $p) {
        "$!srcdir/{$p.name.subst(':', '_', :g)}"
    }
}

# vim: ft=perl6
