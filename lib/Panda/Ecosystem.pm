use Pies;
use JSON::Tiny;
use Shell::Command;

class Panda::Ecosystem does Pies::Ecosystem {
    has $.statefile;
    has $.projectsfile;
    has %!projects;
    has %!states;
    has %!saved-meta;

    sub getfile($src, $dest) {
        pir::load_bytecode__vs('LWP/UserAgent.pir');
        my $res = Q:PIR {
            .local string what, where
            .local pmc ua, response, outfile
            $P0 = find_lex '$src'
            what = repr_unbox_str $P0
            $P0 = find_lex '$dest'
            where = repr_unbox_str $P0
            ua = new ['LWP';'UserAgent']
            response = ua.'get'(what)
            $I0 = response.'code'()
            if $I0 == 200 goto success
            $I0 = 1
            goto end
        success:
            outfile = new ['FileHandle']
            outfile.'open'(where, 'w')
            $S0 = response.'content'()
            outfile.'print'($S0)
            $S0 = "\n"
            outfile.'print'($S0)
            outfile.'close'()
            $I0 = 0
        end:
            %r = perl6_box_int $I0
        };
        $res and die "Unable to fetch $src";
    }

    method flush-states {
        my $fh = open($!statefile, :w);
        for %!states.kv -> $key, $val {
            my $json = to-json %!saved-meta{$key};
            $fh.say: "$key $val $json";
        }
        $fh.close;
    }

    submethod BUILD(:$!statefile, :$!projectsfile) {
        if $!statefile.IO ~~ :f {
            my $fh = open($!statefile);
            for $fh.lines -> $line {
                my ($mod, $state, $json) = split ' ', $line, 3;
                %!states{$mod} = $state;
                %!saved-meta{$mod} = from-json $json;
            }
        }

        self.update if $!projectsfile.IO !~~ :f || $!projectsfile.IO ~~ :z;
        my $list = from-json slurp $!projectsfile;
        unless defined $list {
            die "An unknown error occured while reading the projects file";
        }
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
        getfile 'http://feather.perl6.nl:3000/projects.json',
                $!projectsfile
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

    method project-get-saved-meta(Pies::Project $p) {
        %!saved-meta{$p.name};
    }

    method project-set-state(Pies::Project $p,
                             Pies::Project::State $s) {
        %!states{$p.name} = $s;
        %!saved-meta{$p.name} = $p.metainfo;
        self.flush-states;
    }
}

# vim: ft=perl6
