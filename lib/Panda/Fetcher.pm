use Pies;
use Panda::Common;
use Panda::Resources;
use File::Find;
use File::Mkdir;

class Panda::Fetcher does Pies::Fetcher {
    has $!resources;
    method fetch (Pies::Project $p) {
        my $dest = $!resources.workdir($p);
        my $url  = $p.metainfo<repo-url>;
        given $p.metainfo<repo-type> {
            when 'git' {
                if $dest.IO ~~ :d {
                    indir $dest, {
                        run 'git pull -q'
                        and die "Failed updating the {$p.name} repo";
                    };
                } else {
                    run "git clone -q $url $dest"
                        and die "Failed cloning the {$p.name} repo";
                }
            }
            when 'local' {
                for find(dir => $url).list {
                    # that's sort of ugly, I know, but we need
                    # <repo-url> stripped
                    my $where = "$dest/{$_.dir.substr($url.chars)}";
                    mkdir $where, :p;
                    next if $_.IO ~~ :d;
                    $_.IO.copy("$where/{$_.name}");
                }
            }
            default {
                die "Failed fetching {$p.name}, "
                    ~ "repo-type $_ not supported";
            }
        }
        # returns the directory where the module lies
        # return {$Settings::srcdir} ~ "/$name";
    }
}

# vim: ft=perl6
