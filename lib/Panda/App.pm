module Panda::App {
use Shell::Command;
use Panda::Ecosystem;
use Panda::Project;

# initialize the Panda object
sub make-default-ecosystem(Str $prefix? is copy) is export {
    my $custom-prefix = ?$prefix;
    my $pandadir;
    $prefix = "$*CWD/$prefix" if defined($prefix) && !$*DISTRO.is-win && $prefix !~~ /^ '/' /;
    for grep(*.defined, flat $prefix, %*CUSTOM_LIB<site home>) -> $target {
        $prefix  = $target;
        $pandadir = "$target/panda".IO;
        try mkpath $pandadir unless $pandadir ~~ :d;
        last if $pandadir.w;
    }
    unless $pandadir.w {
        die "Found no writable directory into which panda could be installed";
    }

    my @extra-statefiles;
    unless $custom-prefix or $prefix eq %*CUSTOM_LIB<site> {
        for grep(*.defined, flat $prefix, %*CUSTOM_LIB<site home>) -> $target {
            unless $prefix eq $target {
                @extra-statefiles.push("$target/panda/state");
            }
        }
    }

    # Add the path we're installing to @*INC
    #
    # If we're installing to a custom prefix or we're installing to a standard
    # dir that did not exist, it isn't in @*INC (which will make Build.pm
    # files that depend on the modules we just installed break).
    #
    # If this is already in @*INC, it doesn't harm anything to re-add it.
    @*INC.push("file#" ~ $prefix ~ '/lib');   # TEMPORARY !!!

    return Panda::Ecosystem.new(
        statefile    => "$pandadir/state",
        projectsfile => "$pandadir/projects.json",
        extra-statefiles => @extra-statefiles
    );
}

sub listprojects($panda, :$installed, :$verbose) is export {
    my $es        = $panda.ecosystem;
    my @projects  = $es.project-list.sort(*.name);
       @projects .= grep({ $es.project-get-state($_) ne Panda::Project::State::absent })
                    if $installed;
    my @saved     = @projects.flatmap({ $es.project-get-saved-meta($_) || {} });
    my $max-name  = @projects».name».chars.max;
    my $max-ver   = @projects».version».chars.max;
    my $max-rev   = @saved.flatmap({ $_<source-revision> // '?'})».chars.max;

    for @projects -> $x {
        my $s = do given $es.project-get-state($x) {
            when Panda::Project::State::installed     { '[installed]' }
            when Panda::Project::State::installed-dep { '-dependency-' }
            default                                   { '' }
        }

        my $meta = $s ?? $es.project-get-saved-meta($x) !! $x.metainfo;
        my $url  = $meta<source-url>
                // $meta<support><source>
                // 'UNKNOWN';
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
    for $panda.ecosystem.project-list -> $p {
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
            my $installed;
            if $state ~~ 'installed' {
                $installed = $panda.ecosystem.project-get-saved-meta($x);
                #note $installed.perl;
            }
            print $x.name;
            if $x.version ne '*' {
                my $foo = '';
                if $installed {
                    $foo = " available, {$installed<version>} installed"
                }
                say " (version {$x.version}$foo)";
            } else {
                say ''
            }
            if my $d =$x.metainfo.<description> {
               say $d
            }
            say 'Depends on: ', $x.dependencies.join(', ') if $x.dependencies;
            print 'State: ';
            given $state {
                when 'installed'     {
                    say 'installed';
                }
                when 'installed-dep' {
                    say 'installed as a dependency';
                }
                default {
                    say 'not installed'
                }
            }
            for $x.metainfo.kv -> $k, $v {
                if $k ~~ none(<version name depends description>) {
                    say "{$k.tc}: $v";
                }
            }
        } else {
            say "Project '$p' not found"
        }
    }
}

}

# vim: ft=perl6
