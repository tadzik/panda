use v6;
use Pies;

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
}

# vim: ft=perl6
