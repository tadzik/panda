use v6;
use Pies;

class Panda is Pies {
    use Panda::Ecosystem;
    use Panda::Fetcher;
    use Panda::Builder;
    use Panda::Tester;
    use Panda::Installer;

    has $!srcdir;
    has $!destdir;
    has $!statefile;
    has $!projectsfile;

    submethod BUILD {
        callsame; # attribute initialization
        $!ecosystem = Panda::Ecosystem.new(
            statefile    => $!statefile,
            projectsfile => $!projectsfile,
        );
        $!fetcher   = Panda::Fetcher.new(srcdir => $!srcdir);
        $!builder   = Panda::Builder.new(srcdir => $!srcdir);
        $!tester    = Panda::Tester.new(srcdir => $!srcdir);
        $!installer = Panda::Installer.new(
            srcdir  => $!srcdir,
            destdir => $!destdir
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
        self.announce: "{$p.key.name} depends on {$p.value.name}"
    }
}

# vim: ft=perl6
