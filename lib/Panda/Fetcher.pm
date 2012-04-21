use Pies;
use Panda::Common;
use Panda::Resources;
use File::Find;
use Shell::Command;

class Panda::Fetcher does Pies::Fetcher {
    sub die (Pies::Project $p, $d) is hidden_from_backtrace {
        X::Panda.new($p.name, 'fetch', $d).throw
    }

    has $.resources;
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
                    die $p, "Unable to determine source-type using source-url";
                }
            }
        }
        given $type {
            when 'git' {
                if $dest.IO ~~ :d {
                    indir $dest, {
                        shell 'git pull -q'
                        and die $p, "Failed updating the repo";
                    };
                } else {
                    shell "git clone -q $url $dest"
                        and die $p, "Failed cloning the repo";
                }
            }
            when 'local' {
                for find(dir => $url).list {
                    # that's sort of ugly, I know, but we need
                    # <source-url> stripped
                    my $where = "$dest/{$_.dir.substr($url.chars)}";
                    mkpath $where;
                    next if $_.IO ~~ :d;
                    $_.IO.copy("$where/{$_.name}");
                }
            }
            default {
                die $p, "source-type $_ not supported";
            }
        }
    }
}

# vim: ft=perl6
