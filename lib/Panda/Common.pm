module Panda::Common {
use Shell::Command;

sub find-meta-file(Str $dirname) is export {
    if "$dirname/META.info".IO ~~ :f {
        return "$dirname/META.info";
    }
    if "$dirname/META6.json".IO ~~ :f {
        return "$dirname/META6.json";
    }
}

sub dirname ($mod as Str) is export {
    $mod.subst(':', '_', :g);
}

sub indir ($where, Callable $what) is export {
    mkpath $where;
    temp $*CWD = chdir($where);
    $what()
}

sub withp6lib(&what) is export {
    my $oldp6lib = %*ENV<PERL6LIB>;
    LEAVE {
        if $oldp6lib.defined {
            %*ENV<PERL6LIB> = $oldp6lib;
        }
        else {
            %*ENV<PERL6LIB>:delete;
        }
    }
    my $sep = $*DISTRO.?cur-sep // $*DISTRO.path-sep;
    %*ENV<PERL6LIB> = join $sep,
        $*CWD ~ '/blib/lib',
        $*CWD ~ '/lib',
        %*ENV<PERL6LIB> // ();
    what();
}

sub compsuffix is export { state $ = $*VM.precomp-ext }

sub comptarget is export { state $ = $*VM.precomp-target }

class X::Panda is Exception {
    has $.module is rw;
    has $.stage;
    has $.description;
    has $.bone;

    method new($module, $stage, $description is copy, :$bone) {
        if $description ~~ Failure {
            $description = $description.exception.message
        }
        self.bless(:$module, :$stage, :$description, :$bone)
    }

    method message {
        sprintf "%s stage failed for %s: %s",
                $.stage, $.module, $.description
    }
}

my $has-proc-async = Proc::<Async>:exists;

sub run-and-gather-output(*@command) is export {
    my $output = '';
    my $stdout = '';
    my $stderr = '';
    my $passed;

    if $has-proc-async {
        my $proc = Proc::Async.new(|@command);
        $proc.stdout.tap(-> $chunk {
            print $chunk;
            $output ~= $chunk;
            $stdout ~= $chunk;
        });
        $proc.stderr.tap(-> $chunk {
            print $chunk;
            $output ~= $chunk;
            $stderr ~= $chunk;
        });
        my $p = $proc.start;
        # workaround for OSX, see RT125758
        $p.result;
        $passed = $p.result.exitcode == 0;
    }
    else {
        my $cmd = @command.map({ qq{"$_"} }).join(' ');
        $output ~= "$cmd\n";
        my $p = shell("$cmd 2>&1", :out);
        for $p.out.lines {
            .chars && .say;
            $output ~= "$_\n";
        }
        $p.out.close;
        $passed = $p.exitcode == 0;
    }

    \(:$output, :$stdout, :$stderr, :$passed)
}

}

# vim: ft=perl6
