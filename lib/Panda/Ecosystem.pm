class Panda::Ecosystem {
    use Panda::Project;
    use Panda::Common;
    use JSON::Fast;
    use Shell::Command;

    has $.statefile;
    has @.extra-statefiles;
    has $.projectsfile;
    has @!projects;
    has %!states;
    has %!saved-meta;

    method init-states {
        state $done = False;
        return if $done;
        for flat $!statefile, @!extra-statefiles -> $file {
            if $file.IO ~~ :f {
                my $fh = open($file);
                for $fh.lines -> $line {
                    my ($mod, $state, $json) = split ' ', $line, 3;
                    %!states{$mod} = ::("Panda::Project::State::$state");
                    %!saved-meta{$mod} = from-json $json;
                }
                $fh.close;
            }
        }
        $done = True;
    }

    method flush-states {
        my $fh = open($!statefile, :w);
        for %!states.kv -> $key, $val {
            my $json = to-json %!saved-meta{$key}, :!pretty;
            $fh.say: "$key {$val.Str} $json";
        }
        $fh.close;
    }

    method project-list {
        self.init-projects();
        return @!projects;
    }

    method init-projects {
        state $done = False;
        return if $done;
        self.update() unless $!projectsfile.IO.f;

        my $contents = slurp $!projectsfile;
        my $list = try from-json $contents;
        if $! {
            die "Cannot parse $!projectsfile as JSON: $!";
        }
        unless defined $list {
            die "An unknown error occured while reading the projects file";
        }
        self.init-states();
        my %non-ecosystem = %!saved-meta;
        for $list.list -> $mod {
            my $p = Panda::Project.new(
                name         => $mod<name>,
                version      => $mod<version>,
                dependencies => (flat @($mod<depends>//Empty), @($mod<test-depends>//Empty), @($mod<build-depends>//Empty)).unique.Array,
                metainfo     => $mod,
            );
            self.add-project($p);
            %non-ecosystem{$mod<name>}:delete;
        }
        for %non-ecosystem.kv -> $name, $mod {
            my $p = Panda::Project.new(
                name         => $name,
                version      => $mod<version>,
                dependencies => (flat @($mod<depends>//Empty), @($mod<test-depends>//Empty), @($mod<build-depends>//Empty)).unique.Array,
                metainfo     => $mod,
            );
            self.add-project($p);
        }

        $done = True;
    }

    method update {
        try unlink $!projectsfile;
        my $url = 'http://ecosystem-api.p6c.org/projects.json';
        my $s;
        my $has-http-ua = try require HTTP::UserAgent;
        if $has-http-ua {
            my $ua = ::('HTTP::UserAgent').new;
            my $response = $ua.get($url);
            $!projectsfile.IO.spurt: $response.decoded-content;
        } else {
            # Makeshift HTTP::Tiny
            $s = IO::Socket::INET.new(:host<ecosystem-api.p6c.org>, :port(80));
            $s.print("GET /projects.json HTTP/1.0\r\nHost: ecosystem-api.p6c.org\r\n\r\n");
            my ($buf, $g) = '';

            my $http-header = $s.get;

            if $http-header !~~ /'HTTP/1.'<[01]>' 200 OK'/ {
                die "can't download projects file: $http-header";
            }

            $buf ~= $g while $g = $s.get;

            $!projectsfile.IO.spurt: $buf.split(/\r?\n\r?\n/, 2)[1];
        }

        CATCH {
            die "Could not download module metadata: {$_.message}"
        }
    }

    method add-project(Panda::Project $p) {
        @!projects.push: $p;
    }

    method get-project($p as Str) {
        self.init-projects();
        my @cands;
        for @!projects {
            if .name eq $p {
                @cands.push: $_
            }
        }
        if +@cands {
            return @cands.sort(*.version).reverse[0];
        }
        for @!projects -> $cand {
            if $cand.metainfo<provides>.keys.grep($p) {
                say "$cand provides the requested $p";
                return $cand;
            }
        }
    }

    method suggest-project($p as Str) {
        self.init-projects();
        my &canonical = *.subst(/ <[\- _ :]>+ /, "", :g).lc;
        my $cpname = canonical($p);
        for @!projects.map(*.name) {
            return $_ if canonical($_) eq $cpname;
        }
        return Nil;
    }

    method project-get-state(Panda::Project $p) {
        self.init-states();
        %!states{$p.name} // Panda::Project::State::absent
    }

    method is-installed(Panda::Project $p) {
        self.project-get-state($p) != Panda::Project::State::absent
    }

    method project-get-saved-meta(Panda::Project $p) {
        self.init-states();
        %!saved-meta{$p.name};
    }

    method project-set-state(Panda::Project $p,
                             Panda::Project::State $s) {
        self.init-states();
        %!states{$p.name} = $s;
        %!saved-meta{$p.name} = $p.metainfo;
        self.flush-states;
    }
}

# vim: ft=perl6
