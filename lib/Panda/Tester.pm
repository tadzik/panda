class Panda::Tester {
use Panda::Common;

method test($where, :$bone, :$prove-command = $*DISTRO.name eq 'mswin32' ?? 'prove.bat' !! 'prove', :@deps) {
    indir $where, {
        my Bool $run-default = True;
        if "Build.pm".IO.f {
            @*INC.push('file#.');   # TEMPORARY !!!
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
                my $libs = '';
                for @deps -> $lib {
                    $libs ~= ' -M' ~ $lib;
                }
                my ( :$output, :$stdout, :$stderr, :$passed ) := run-and-gather-output($prove-command, '-e', "$*EXECUTABLE $libs -Ilib", '-r', 't/');

                if $bone {
                    $bone.test-output = $output;
                    $bone.test-stdout = $stdout;
                    $bone.test-stderr = $stderr;
                    $bone.test-passed = $passed;
                }

                fail "Tests failed" unless $passed;
            }
        }
    };
    return True;
}

}

# vim: ft=perl6
