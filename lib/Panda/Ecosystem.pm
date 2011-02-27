use Pies;
use JSON::Tiny;

multi sub mkdir(Str $name, $mode = 0o777, :$p!) {
    for [\~] $name.split('/').map({"$_/"}) {
        mkdir($_) unless .IO.d
    }
}

class Panda::Ecosystem is Pies::Ecosystem {
    has $!statefile;
    has $!projectsfile;
    has %!projects;
    has %!states;
    
    # those two methods will be called only if needed
    # given the slowness of Rakudo and JSON it's better
    # if they aren't called ever :)
    method !init_states {
        if $!statefile.IO ~~ :f {
            my $fh = open($!statefile);
            for $fh.lines -> $line {
                my ($mod, $state) = split ' ', $line;
                %!states{$mod} = $state;
            }
        }
    }

    method !init_projects {
        my $list = from-json slurp $!projectsfile;
        for $list.list -> $mod {
            my $p = Pies::Project.new(
                name         => $mod<name>,
                version      => $mod<version>,
                dependencies => $mod<depends>,
                metainfo     => $mod,
            );
            %!projects{$mod<name>} = $p;
        }
    }

    method project-list {
        self!init_projects unless %!projects;
        return %!projects.keys
    }

    # Pies::Ecosystem methods

    method add-project(Pies::Project $p) {
        %!projects.push($p.name, $p);
    }

    method get-project($p as Str) {
        self!init_projects unless %!projects;
        %!projects{$p}
    }

    method project-get-state(Pies::Project $p) {
        self!init_states unless %!states;
        %!states{$p.name} // 'absent'
    }

    method project-set-state(Pies::Project $p,
                             Pies::Project::State $s) {
        %!states{$p.name} = $s;
    }
}

# vim: ft=perl6
