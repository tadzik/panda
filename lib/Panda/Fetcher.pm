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
        my $url  = $p.metainfo<source-url>  // $p.metainfo<repo-url>;
        my $type = $p.metainfo<source-type> // $p.metainfo<repo-type>;
        unless $type {
            given $url {
                when /^ [ 'git:' | 'http' 's'? '://github.com/' ] / {
                    $type = 'git';
                }
                default {
                    die $p, "Unable to determine source-type using source-url";
                }
            }
            $p.metainfo<source-type> = $type;
        }
        given $type {
            when 'git' {
                if $dest.IO ~~ :d {
                    indir $dest, {
                        shell 'git pull -q'
                        and die $p, "Failed updating the repo";
                    };
                } else {
                    shell "git clone -q $url \"$dest\""
                        and die $p, "Failed cloning the repo";
                }

                indir $dest, {
                    my $desc = qx{git describe --always --dirty}.chomp;
                    $p.metainfo<source-revision> = $desc;
                };
            }
            when 'local' {
                for find(dir => $url).list {
                    # that's sort of ugly, I know, but we need
                    # <source-url> stripped
                    my $d = $_.dir.substr($url.chars);
                    next if $d ~~ /^ '/'? '.git'/; # skip VCS files
                    my $where = "$dest/$d";
                    mkpath $where;
                    next if $_.IO ~~ :d;
                    $_.IO.copy("$where/{$_.name}");
                }
            }
            default {
                die $p, "source-type $_ not supported";
            }
        }
        return;
    }
}

# vim: ft=perl6
