use Pies;
use Panda::Common;

class Panda::Fetcher does Pies::Fetcher {
    has $!resources;
    method fetch (Pies::Project $p) {
        my $dir = $!resources.workdir($p);
        unless $p.metainfo<repo-type> eq 'git' {
            die "Failed fetching {$p.name}, "
                ~ "sources other than git not yet supported"
        }
        my $url = $p.metainfo<repo-url>;
        if $dir.IO ~~ :d {
            indir $dir, {
                run 'git pull -q'
                    and die "Failed updating the {$p.name} repo";
            };
        } else {
            run "git clone -q $url $dir"
                and die "Failed cloning the {$p.name} repo";
        }
        # returns the directory where the module lies
        # return {$Settings::srcdir} ~ "/$name";
    }
}

# vim: ft=perl6
