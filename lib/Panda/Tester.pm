use Pies;
use Panda::Common;

class Panda::Tester does Pies::Tester {
    sub die (Pies::Project $p, $d) is hidden_from_backtrace {
        X::Panda.new($p.name, 'test', $d).throw
    }

    has $.resources;

    method test(Pies::Project $p) {
        indir $!resources.workdir($p), {
            if 'Makefile'.IO ~~ :f {
                shell 'make test' and die $p, "'make test' failed";
            } elsif 't'.IO ~~ :d {
                my $p6lib = "{cwd}/blib/lib:{cwd}/lib:{%*ENV<PERL6LIB>}";
                my $c = "env PERL6LIB=$p6lib prove -e perl6 -r t/";
                shell $c and die $p, "Tests failed";
            }
        };
    }
}

# vim: ft=perl6
