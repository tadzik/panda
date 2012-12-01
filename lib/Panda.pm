use v6;
use Pies;
use JSON::Tiny;
use Panda::Ecosystem;
use Panda::Fetcher;
use Panda::Builder;
use Panda::Tester;
use Panda::Installer;
use Panda::Resources;

class Panda is Pies {
    has $.srcdir;
    has $.destdir;
    has $.statefile;
    has $.projectsfile;
    has $.resources;

    method new(:$srcdir, :$destdir, :$statefile, :$projectsfile) {
        my $ecosystem = Panda::Ecosystem.new(
            :$statefile,
            :$projectsfile,
        );
        my $resources = Panda::Resources.new(:$srcdir);
        my $fetcher   = Panda::Fetcher.new(:$resources);
        my $builder   = Panda::Builder.new(:$resources);
        my $tester    = Panda::Tester.new(:$resources);
        my $installer = Panda::Installer.new(
            :$resources,
            :$destdir,
        );
        self.bless(*, :$srcdir, :$destdir, :$statefile, :$projectsfile,
                      :$ecosystem, :$fetcher, :$builder, :$tester,
                      :$installer);
    }

    multi method announce(Str $what) {
        say "==> $what"
    }

    multi method announce('fetching', Pies::Project $p) {
        self.announce: "Fetching {$p.name}"
    }

    multi method announce('building', Pies::Project $p) {
        self.announce: "Building {$p.name}"
    }

    multi method announce('testing', Pies::Project $p) {
        self.announce: "Testing {$p.name}"
    }

    multi method announce('installing', Pies::Project $p) {
        self.announce: "Installing {$p.name}"
    }

    multi method announce('success', Pies::Project $p) {
        self.announce: "Successfully installed {$p.name}"
    }

    multi method announce('depends', Pair $p) {
        self.announce: "{$p.key.name} depends on {$p.value.join(", ")}"
    }

    method resolve($proj as Str, Bool :$nodeps, Bool :$notests) {
        if $proj.IO ~~ :d and "$proj/META.info".IO ~~ :f {
            my $mod = from-json slurp "$proj/META.info";
            $mod<source-type> = "local";
            $mod<source-url>  = $proj;
            my $p = Pies::Project.new(
                name         => $mod<name>,
                version      => $mod<version>,
                dependencies => $mod<depends>,
                metainfo     => $mod,
            );
            if $.ecosystem.get-project($p.name) {
                self.announce: "Installing {$p.name} "
                               ~ "from a local directory '$proj'";
            }
            $.ecosystem.add-project($p);
            nextwith($p.name, :$nodeps, :$notests);
        }
        nextsame;

        CATCH {
            if $_ !~~ X::Panda {
                die X::Panda.new($proj, 'resolve', $_.message);
            }
            if $_.module ne $proj {
                X::Panda.new($proj, 'resolve',
                    'Dependency resolution has failed: '
                    ~ "stage {$_.stage} failed for {$_.module}"
                ).throw;
            }
            $_.rethrow;
        }
    }
}

# vim: ft=perl6
