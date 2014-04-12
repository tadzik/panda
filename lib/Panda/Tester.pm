class Panda::Tester;
use Panda::Common;

method test($where, :$prove-command = 'prove') {
    indir $where, {
        if 't'.IO ~~ :d {
            withp6lib {
                my $c = "$prove-command -e $*EXECUTABLE -r t/";
                shell $c or fail "Tests failed";
            }
        }
    };
    return True;
}

# vim: ft=perl6
