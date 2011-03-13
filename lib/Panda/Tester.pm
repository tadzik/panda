use Pies;
use Panda::Common;

class Panda::Tester does Pies::Tester {
    has $!resources;

    method test(Pies::Project $p) {
        indir $!resources.workdir($p), {
            if 'Makefile'.IO ~~ :f {
                run 'make test'
                    and die "'make test' failed for {$p.name}";
            } elsif 't'.IO ~~ :d {
                my $p6lib = "{cwd}/blib/lib:{cwd}/lib:{%*ENV<PERL6LIB>}";
                my $c = "env PERL6LIB=$p6lib prove -e perl6 -r t/";
                run $c and die "Tests failed for {$p.name}";
            }
        };
    }
}

# vim: ft=perl6
