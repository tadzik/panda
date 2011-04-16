use Pies;
use Panda::Common;
use Panda::Resources;
use File::Find;
use File::Mkdir;

class Panda::Fetcher does Pies::Fetcher {
    has $!resources;
    method fetch (Pies::Project $p) {
        my $dest = $!resources.workdir($p);
        # the repo-* variants are kept for backwards compatibility only
        my $url  = $p.metainfo<source-url> // $p.metainfo<repo-url>;
        my $type = $p.metainfo<source-type> // $p.metainfo<repo-type>;
        unless $type {
            given $url {
                when /^git:/ {
                    $type = 'git';
                }
                default {
                    die "Failed fetching {$p.name}, unable to determine "
                      ~ "source-type with the source-url";
                }
            }
        }
        given $type {
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
                    # <source-url> stripped
                    my $where = "$dest/{$_.dir.substr($url.chars)}";
                    mkdir $where, :p;
                    next if $_.IO ~~ :d;
                    $_.IO.copy("$where/{$_.name}");
                }
            }
            default {
                die "Failed fetching {$p.name}, "
                    ~ "source-type $_ not supported";
            }
        }
        # returns the directory where the module lies
        # return {$Settings::srcdir} ~ "/$name";
    }
}

# vim: ft=perl6
