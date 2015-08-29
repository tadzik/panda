use v6;
use Panda::Common;
use Panda::Ecosystem;
use Panda::Fetcher;
use Panda::Builder;
use Panda::Tester;
use Panda::Installer;
use Panda::Bundler;
use Panda::Reporter;
use Shell::Command;
use JSON::Fast;

sub tmpdir {
    state $i = 0;
    ".panda-work/{time}_{$i++}".IO.absolute
}

class Panda {
    has $.ecosystem;
    has $.fetcher   = Panda::Fetcher.new;
    has $.builder   = Panda::Builder.new;
    has $.tester    = Panda::Tester.new;
    has $.installer = Panda::Installer.new;
    has $.bundler   = Panda::Bundler.new;

    multi method announce(Str $what) {
        say "==> $what"
    }

    multi method announce('fetching', Panda::Project $p) {
        self.announce: "Fetching {$p.name}"
    }

    multi method announce('building', Panda::Project $p) {
        self.announce: "Building {$p.name}"
    }

    multi method announce('testing', Panda::Project $p) {
        self.announce: "Testing {$p.name}"
    }

    multi method announce('installing', Panda::Project $p) {
        self.announce: "Installing {$p.name}"
    }

    multi method announce('success', Panda::Project $p) {
        self.announce: "Successfully installed {$p.name}"
    }

    multi method announce('depends', Pair $p) {
        self.announce: "{$p.key.name} depends on {$p.value.join(", ")}"
    }

    method project-from-local($proj as Str) {
        my $metafile = find-meta-file($proj);
        if $proj.IO ~~ :d and $metafile {
            if $proj !~~ rx{'/'|'.'|'\\'} {
                die X::Panda.new($proj, 'resolve',
                        "Possibly ambiguous module name requested." 
                        ~ " Please specify at least one slash if you really mean to install"
                        ~ " from local directory (e.g. ./$proj)")
            }
            my $mod = from-json slurp $metafile;
            $mod<source-url>  = $proj;
            return Panda::Project.new(
                name         => $mod<name>,
                version      => $mod<version>,
                dependencies => (flat @($mod<depends>//Empty), @($mod<test-depends>//Empty), @($mod<build-depends>//Empty)).unique.Array,
                metainfo     => $mod,
            );
        }
        return False;
    }

    method project-from-git($proj as Str, $tmpdir) {
        if $proj ~~ m{^git\:\/\/} {
            mkpath $tmpdir;
            $.fetcher.fetch($proj, $tmpdir);
            my $mod = from-json slurp find-meta-file($tmpdir);
            $mod<source-url>  = ~$tmpdir;
            return Panda::Project.new(
                name         => $mod<name>,
                version      => $mod<version>,
                dependencies => (flat @($mod<depends>//Empty), @($mod<test-depends>//Empty), @($mod<build-depends>//Empty)).unique.Array,
                metainfo     => $mod,
            );
        }
        return False;
    }

    method look(Panda::Project $bone) {
        my $dir = tmpdir();

        self.announce('fetching', $bone);
        my $source = $bone.metainfo<source-url>
                  // $bone.metainfo<support><source>;
        unless $source {
            die X::Panda.new($bone.name, 'fetch', 'source-url meta info missing')
        }
        unless $_ = $.fetcher.fetch($source, $dir) {
            die X::Panda.new($bone.name, 'fetch', $_)
        }

        my $shell = %*ENV<SHELL>;
        $shell ||= %*ENV<ComSpec>
            if $*DISTRO.is-win;

        if $shell {

            my $*CWD = $dir;
            self.announce("Entering $dir with $shell\n");
            shell $shell or fail "Unable to invoke shell: $shell"
        } else {
            self.announce("You don't seem to have a SHELL");
        }
    }

    method install(Panda::Project $bone, $nodeps, $notests,
                   $isdep as Bool, :$rebuild = True, :$prefix) {
        my $cwd = $*CWD;
        my $dir = tmpdir();
        my $reports-file = ($.ecosystem.statefile.IO.dirname ~ '/reports.' ~ $*PERL.compiler.version).IO;
        self.announce('fetching', $bone);
        my $source = $bone.metainfo<source-url>
                  // $bone.metainfo<support><source>;
        unless $source {
            die X::Panda.new($bone.name, 'fetch', 'source-url meta info missing')
        }
        unless $_ = $.fetcher.fetch($source, $dir) {
            die X::Panda.new($bone.name, 'fetch', $_)
        }
        self.announce('building', $bone);
        unless $_ = $.builder.build($dir, :$bone) {
            die X::Panda.new($bone.name, 'build', $_)
        }
        unless $notests {
            self.announce('testing', $bone);
            my %args = %*ENV<PROVE_COMMAND>
                ??  prove-command => %*ENV<PROVE_COMMAND>
                !! ();
            unless $_ = $.tester.test($dir, :$bone, |%args) {
                die X::Panda.new($bone.name, 'test', $_, :$bone)
            }
        }
        self.announce('installing', $bone);
        $.installer.install($dir, $prefix, :$bone);
        my $s = $isdep ?? Panda::Project::State::installed-dep
                       !! Panda::Project::State::installed;
        $.ecosystem.project-set-state($bone, $s);
        self.announce('success', $bone);
        Panda::Reporter.new( :$bone, :$reports-file ).submit;

        chdir $cwd;
        rm_rf $dir;

        CATCH {
            Panda::Reporter.new( :$bone, :$reports-file ).submit;
            chdir $cwd;
            rm_rf $dir;
        }
    }

    method get-deps(Panda::Project $bone) {
        my @bonedeps = $bone.dependencies.grep(*.defined).map({
            next if $_ eq 'Test' | 'NativeCall' | 'nqp' | 'lib' | 'MONKEY-TYPING'; # XXX Handle dists properly that are shipped by a compiler.
            $.ecosystem.get-project($_)
                or die X::Panda.new($bone.name, 'resolve',
                                    "Dependency $_ is not present in the module ecosystem")
        }).grep({
            $.ecosystem.project-get-state($_) == Panda::Project::State::absent
        });
        return Empty unless +@bonedeps;
        self.announce('depends', $bone => @bonedeps».name);
        my @deps;
        for @bonedeps -> $p {
            @deps.push: flat self.get-deps($p), $p;
        }
        return @deps;
    }

    method resolve($proj as Str is copy, Bool :$nodeps, Bool :$notests,
                   :$action = 'install', Str :$prefix) {
        my $tmpdir = tmpdir();
        LEAVE { rm_rf $tmpdir if $tmpdir.IO.e }
        mkpath $tmpdir;

        my $bone = self.project-from-local($proj);
        # Warn users that it's from a local directory,
        # may not be what they wanted
        self.announce: "Installing {$bone.name} "
                       ~ "from a local directory '$proj'"
                       if $bone and $action eq 'install';
        $bone ||= self.project-from-git($proj, $tmpdir);
        if $bone {
            $.ecosystem.add-project($bone);
            $proj = $bone.name;
        } else {
            $bone = $.ecosystem.get-project($proj);
        }

        if not $bone {
            sub die($m) { X::Panda.new($proj, 'resolve', $m).throw }
            my $suggestion = $.ecosystem.suggest-project($proj);
            die "Project $proj not found in the ecosystem. Maybe you meant $suggestion?" if $suggestion;
            die "Project $proj not found in the ecosystem";
        }

        unless $nodeps {
            my @deps = self.get-deps($bone).unique;
            @deps.=grep: {
                $.ecosystem.project-get-state($_)
                    == Panda::Project::absent
            };
            self.install($_, $nodeps, $notests, 1) for @deps;
        }

        given $action {
            when 'install' {
                self.install($bone, $nodeps, $notests, 0, :$prefix);
            }
            when 'install-deps-only' { }
            when 'look'    { self.look($bone) };
        }
    }
}

# vim: ft=perl6
