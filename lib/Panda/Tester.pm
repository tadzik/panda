use Pies;
use Panda::Common;

class Panda::Tester does Pies::Tester {
    sub die (Pies::Project $p, $d) is hidden_from_backtrace {
        X::Panda.new($p.name, 'test', $d).throw
    }

    has $.resources;

    method test(Pies::Project $p) {
        indir $!resources.workdir($p), {
            if 't'.IO ~~ :d {
                my $sep = $*VM<config><osname> eq 'MSWin32' ?? ';' !! ':';
                my $p6lib = join $sep,
                    cwd() ~ '/blib/lib',
                    cwd() ~ '/lib',
                    %*ENV<PERL6LIB> // '';
                my $c = "env PERL6LIB=$p6lib prove -e perl6 -r t/";
                shell $c and die $p, "Tests failed";
            }
        };
    }
}

# vim: ft=perl6
