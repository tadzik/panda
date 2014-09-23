class Panda::Tester;
use Panda::Common;

method test($where, :$prove-command = 'prove') {
    indir $where, {
        my Bool $run-default = True;
        if "Build.pm".IO.f {
            @*INC.push('.');
            GLOBAL::<Build>:delete;
            require 'Build.pm';
            if ::('Build').isa(Panda::Tester) {
                $run-default = False;
                ::('Build').new.test($where, :$prove-command);
            }
            @*INC.pop;
        }

        if $run-default && 't'.IO ~~ :d {
            withp6lib {
                my $c = "$prove-command -e $*EXECUTABLE -r t/";
                shell $c or fail "Tests failed";
            }
        }
    };
    return True;
}

# vim: ft=perl6
