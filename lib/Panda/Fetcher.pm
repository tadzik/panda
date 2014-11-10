class Panda::Fetcher;
use File::Find;
use Shell::Command;

method fetch($from, $to) {
    given $from {
        when /\.git$/ {
            return git-fetch $from, $to;
        }
        when /^ $<schema>=[<alnum><[+.-]+alnum>*] '://' / {
            when $<schema> {
                when /^'git://'/ {
                    return git-fetch $from, $to;
                }
                when /^[http|https]'+git://'/ {
                    return git-fetch $from.subst(/'+git'/, ''), $to;
                }
                when /^'file://'/ {
                    return local-fetch $from.subst(/^'file://'/, ''), $to;
                }
                default {
                    # OUTER.proceed would be nice, were it implemented!
                    fail "Unable to handle source '$from'"
                }
            }
        }
        when *.IO.d {
            local-fetch $from, $to;
        }
        default {
            fail "Unable to handle source '$from'"
        }
    }
    return True;
}

sub git-fetch($from, $to) {
    shell "git clone -q $from \"$to\""
        or fail "Failed cloning git repository '$from'";
    return True;
}

sub local-fetch($from, $to) {
    # We need to eagerify this, as we'll sometimes
    # copy files to a subdirectory of $from
    my $cleanup       = $from.IO.cleanup;
    my $cleanup_chars = $cleanup.chars;
    for eager find(dir => $from).list {
        my $io = .IO;
        my $d  = $*SPEC.catpath($io.volume, $io.dirname, '');
        # We need to cleanup the path, because the returned elems are too.
        if ($d.Str.index(~$cleanup) // -1) == 0 {
            $d = $d.substr($cleanup_chars)
        }

        next if $d ~~ /^ '/'? '.git'/; # skip VCS files
        my $where = "$to/$d";
        mkpath $where;
        next if $io ~~ :d;
        $io.copy("$where/{$io.basename}");
    }
    return True;
}

# vim: ft=perl6
