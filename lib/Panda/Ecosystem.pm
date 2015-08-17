class Panda::Ecosystem {
    use Panda::Project;
    use Panda::Common;
    use JSON::Tiny;
    use Shell::Command;

    has $.statefile;
    has @.extra-statefiles;
    has $.projectsfile;
    has %!projects;
    has %!states;
    has %!saved-meta;

    method flush-states {
        my $fh = open($!statefile, :w);
        for %!states.kv -> $key, $val {
            my $json = to-json %!saved-meta{$key};
            $fh.say: "$key {$val.Str} $json";
        }
        $fh.close;
    }

    submethod BUILD(:$!statefile, :$!projectsfile, :@!extra-statefiles) {
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

        self.update if $!projectsfile.IO !~~ :f || $!projectsfile.IO ~~ :z;
        my $contents = slurp $!projectsfile;
        my $list = try from-json $contents;
        if $! {
            die "Cannot parse $!projectsfile as JSON: $!";
        }
        unless defined $list {
            die "An unknown error occured while reading the projects file";
        }
        my %non-ecosystem = %!saved-meta;
        for $list.list -> $mod {
            my $p = Panda::Project.new(
                name         => $mod<name>,
                version      => $mod<version>,
                dependencies => [($mod<depends> (|) $mod<test-depends> (|) $mod<build-depends>).list.flat],
                metainfo     => $mod,
            );
            self.add-project($p);
            %non-ecosystem{$mod<name>}:delete;
        }
        for %non-ecosystem.kv -> $name, $mod {
            my $p = Panda::Project.new(
                name         => $name,
                version      => $mod<version>,
                dependencies => [($mod<depends> (|) $mod<test-depends> (|) $mod<build-depends>).list.flat],
                metainfo     => $mod,
            );
            self.add-project($p);
        }
    }

    method project-list {
        return %!projects.values
    }

    method update {
        try unlink $!projectsfile;
        my $s;
        if  %*ENV<http_proxy> {
          my ($host, $port) = %*ENV<http_proxy>.split('/').[2].split(':');
          $s = IO::Socket::INET.new(host=>$host, port=>$port.Int);
          $s.print("GET http://ecosystem-api.p6c.org/projects.json HTTP/1.1\r\nHost: ecosystem-api.p6c.org\r\nAccept: */*\r\nConnection: Close\r\n\r\n");
        }
        else {
          $s = IO::Socket::INET.new(:host<ecosystem-api.p6c.org>, :port(80));
          $s.print("GET /projects.json HTTP/1.0\r\nHost: ecosystem-api.p6c.org\r\n\r\n");
        }
        my ($buf, $g) = '';

        my $http-header = $s.get;

        if $http-header !~~ /'HTTP/1.'<[01]>' 200 OK'/ {
            die "can't download projects file: $http-header";
        }

        $buf ~= $g while $g = $s.get;

        if  %*ENV<http_proxy> {
          $buf.=subst(:g,/'git://'/,'http://');
        }
        
        given open($!projectsfile, :w) {
            .say: $buf.split(/\r?\n\r?\n/, 2)[1];
            .close;
        }

        CATCH {
            die "Could not download module metadata: {$_.message}"
        }
    }

    method add-project(Panda::Project $p) {
        %!projects{$p.name} = $p;
    }

    method get-project($p as Str) {
        %!projects{$p}
    }

    method suggest-project($p as Str) {
        my &canonical = *.subst(/ <[\- _ :]>+ /, "", :g).lc;
        my $cpname = canonical($p);
        for %!projects.keys {
            return $_ if canonical($_) eq $cpname;
        }
        return Nil;
    }

    method project-get-state(Panda::Project $p) {
        %!states{$p.name} // Panda::Project::State::absent
    }

    method is-installed(Panda::Project $p) {
        self.project-get-state($p) != Panda::Project::State::absent
    }

    method project-get-saved-meta(Panda::Project $p) {
        %!saved-meta{$p.name};
    }

    method project-set-state(Panda::Project $p,
                             Panda::Project::State $s) {
        %!states{$p.name} = $s;
        %!saved-meta{$p.name} = $p.metainfo;
        self.flush-states;
    }

    method revdeps($name as Str, Bool :$installed) {
        my @ret;
        for self.project-list -> $p {
            if any($p.dependencies) eq $name {
                if !$installed or self.is-installed($p) {
                    @ret.push: $p, self.revdeps($p, :$installed);
                }
            }
        }
        my %dependencies;
        return Empty unless +@ret;
        for @ret {
            %dependencies{.name} = .dependencies
        }
        # .map is needed because topo-sort sometimes stringifies (???)
        return topo-sort(@ret, %dependencies).map({self.get-project(~$_)});
    }
}

# vim: ft=perl6
