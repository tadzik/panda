class Panda::Ecosystem {
    use Panda::Project;
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
        for $!statefile, @!extra-statefiles -> $file {
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
        my $list = from-json slurp $!projectsfile;
        unless defined $list {
            die "An unknown error occured while reading the projects file";
        }
        my %non-ecosystem = %!saved-meta;
        for $list.list -> $mod {
            my $p = Panda::Project.new(
                name         => $mod<name>,
                version      => $mod<version>,
                dependencies => $mod<depends>,
                metainfo     => $mod,
            );
            self.add-project($p);
            %non-ecosystem{$mod<name>}:delete;
        }
        for %non-ecosystem.kv -> $name, $mod {
            my $p = Panda::Project.new(
                name         => $name,
                version      => $mod<version>,
                dependencies => $mod<depends>,
                metainfo     => $mod,
            );
            self.add-project($p);
        }
    }

    method project-list {
        return %!projects.keys
    }

    method update {
        try unlink $!projectsfile;
        my $s = IO::Socket::INET.new(:host<feather.perl6.nl>, :port(3000));
        $s.send("GET /projects.json HTTP/1.0\n\n");
        my ($buf, $g) = '';
        $buf ~= $g while $g = $s.get;
        
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
        %!states{$p.name} // Panda::Project::absent
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
}

# vim: ft=perl6
