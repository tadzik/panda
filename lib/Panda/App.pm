module Panda::App;
use Panda::Project;

sub listprojects($panda, :$installed, :$verbose) is export {
    my $es        = $panda.ecosystem;
    my @projects  = $es.project-list.sort.map: { $es.get-project($_) };
       @projects .= grep({ $es.project-get-state($_) ne Panda::Project::State::absent })
                    if $installed;
    my @saved     = @projects.map({ $es.project-get-saved-meta($_) || {} });
    my $max-name  = @projects».name».chars.max;
    my $max-ver   = @projects».version».chars.max;
    my $max-rev   = @saved.map({ $_<source-revision> // '?'})».chars.max;

    for @projects -> $x {
        my $s = do given $es.project-get-state($x) {
            when Panda::Project::State::installed     { '[installed]' }
            when Panda::Project::State::installed-dep { '-dependency-' }
            default                                   { '' }
        }

        my $meta = $s ?? $es.project-get-saved-meta($x) !! $x.metainfo;
        my $url  = $meta<source-url> // $meta<repo-url> // 'UNKNOWN';
        my $rev  = $meta<source-revision> // '?';
        my $ver  = $meta<version>;

        if ($verbose) {
            printf "%-{$max-name}s  %-12s  %-{$max-ver}s  %-{$max-rev}s  %s\n",
               $x.name, $s, $ver, $rev, $url;
        }
        else {
            printf "%-{$max-name}s  %-12s\n",
               $x.name, $s;
        }
    }
}

sub wrap ($str) is export {
    return $str.comb(/ . ** 0..40 [ << | $ ]/).grep({ .chars > 0 }).join("\n" ~ " " x 36);
}

sub search-projects($panda, $string) is export {
    for $panda.ecosystem.project-list -> $project {
        my $p = $panda.ecosystem.get-project($project);
        next unless $p.name ~~ /:i $string / || $p.metainfo<description> ~~ /:i $string /;
        printf "%-24s %-10s %s\n",$p.name,$p.version, wrap($p.metainfo<description>);
    }
}

sub projectinfo($panda, @args) is export {
    for @args -> $p {
        my $x = $panda.ecosystem.get-project($p);
        $x = $panda.project-from-local($p) unless $x;
        if $x {
            my $state = $panda.ecosystem.project-get-state($x);
            say 'PROJECT LIST:';
            say $x.name => $x.version;
            say 'Depends on:' => $x.dependencies.Str if $x.dependencies;
            given $state {
                when 'installed'     {
                    say 'State' => 'installed';
                }
                when 'installed-dep' {
                    say 'State' => 'installed as a dependency';
                }
            }
            for $x.metainfo.kv -> $k, $v {
                if $k ~~ none('version', 'name', 'depends') {
                    say $k.tc => $v;
                }
            }
            if $state ~~ /^ 'installed' / {
                say 'INSTALLED VERSION:';
                .say for $panda.ecosystem.project-get-saved-meta($x).pairs.sort;
            }
            say '';
        } else {
            say "Project '$p' not found"
        }
    }
}

# vim: ft=perl6
