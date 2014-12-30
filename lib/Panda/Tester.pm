class Panda::Tester;
use Panda::Common;

method test($where, :$bone, :$prove-command = 'prove') {
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
                my $cmd    = "$prove-command -e $*EXECUTABLE -r t/";
                my $handle = pipe("$cmd 2>&1", :r);
                my $output = '';
                for $handle.lines {
                    .chars && .say;
                    $output ~= "$_\n";
                }
                my $passed = $handle.close.status == 0;

                if $bone {
                    $bone.test-output = $output;
                    $bone.test-passed = $passed;
                }

                fail "Tests failed" unless $passed;
            }
        }
    };
    return True;
}

# vim: ft=perl6
