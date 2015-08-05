module Panda::Common {
use Shell::Command;

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

sub topo-sort(@modules, %dependencies) is export {
    my @order;
    my %color_of = @modules X=> 'not yet visited';
    sub dfs-visit($module) {
        %color_of{$module} = 'visited';
        for %dependencies{$module}.list -> $used {
            if (%color_of{$used} // '') eq 'not yet visited' {
                dfs-visit($used);
            }
        }
        push @order, $module;
    }

    for @modules -> $module {
        if %color_of{$module} eq 'not yet visited' {
            dfs-visit($module);
        }
    }
    @order;
}

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

sub run-and-gather-output(*@command) is export {
    my $output = '';
    my $stdout = '';
    my $stderr = '';

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
    my $passed = $p.result.exitcode == 0;

    :$output, :$stdout, :$stderr, :$passed
}

}

# vim: ft=perl6
