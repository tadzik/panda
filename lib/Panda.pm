use v6;
use Pies;
use JSON::Tiny;

class Panda is Pies {
    use Panda::Ecosystem;
    use Panda::Fetcher;
    use Panda::Builder;
    use Panda::Tester;
    use Panda::Installer;
    use Panda::Resources;

    has $!srcdir;
    has $!destdir;
    has $!statefile;
    has $!projectsfile;
    has $!resources;

    submethod BUILD {
        callsame; # attribute initialization
        $!ecosystem = Panda::Ecosystem.new(
            statefile    => $!statefile,
            projectsfile => $!projectsfile,
        );
        $!resources = Panda::Resources.new(srcdir => $!srcdir);
        $!fetcher   = Panda::Fetcher.new(resources => $!resources);
        $!builder   = Panda::Builder.new(resources => $!resources);
        $!tester    = Panda::Tester.new(resources => $!resources);
        $!installer = Panda::Installer.new(
            resources => $!resources,
            destdir => $!destdir,
        );
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
        self.announce: "Succesfully installed {$p.name}"
    }

    multi method announce('depends', Pair $p) {
        self.announce: "{$p.key.name} depends on {$p.value.join(", ")}"
    }

    method resolve($proj as Str, Bool :$nodeps, Bool :$notests) {
        if $proj.IO ~~ :d and "$proj/META.info".IO ~~ :f {
            my $mod = from-json slurp "$proj/META.info";
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
    }
}

# vim: ft=perl6
