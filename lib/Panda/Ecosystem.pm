use Pies;
use JSON::Tiny;
use Shell::Command;

class Panda::Ecosystem does Pies::Ecosystem {
    has $.statefile;
    has $.projectsfile;
    has %!projects;
    has %!states;

    method flush-states {
        my $fh = open($!statefile, :w);
        for %!states.kv -> $key, $val {
            $fh.say: "$key $val";
        }
        $fh.close;
    }

    submethod BUILD(:$!statefile, :$!projectsfile) {
        if $!statefile.IO ~~ :f {
            my $fh = open($!statefile);
            for $fh.lines -> $line {
                my ($mod, $state) = split ' ', $line;
                %!states{$mod} = $state;
            }
        }

        self.update if not $!projectsfile.IO ~~ :f;
        my $list = from-json slurp $!projectsfile;
        for $list.list -> $mod {
            my $p = Pies::Project.new(
                name         => $mod<name>,
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
        shell "wget 'feather.perl6.nl:3000/list' -O '$!projectsfile'";
    }

    # Pies::Ecosystem methods

    method add-project(Pies::Project $p) {
        %!projects{$p.name} = $p;
    }

    method get-project($p as Str) {
        %!projects{$p}
    }

    method project-get-state(Pies::Project $p) {
        %!states{$p.name} // 'absent'
    }

    method project-set-state(Pies::Project $p,
                             Pies::Project::State $s) {
        %!states{$p.name} = $s;
        self.flush-states;
    }
}

# vim: ft=perl6
