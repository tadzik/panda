class Panda::Fetcher;
use Panda::Common;
use File::Find;
use Shell::Command;
use HTTP::UserAgent;
use Compress::Zlib;
use Archive::Tar;

method fetch($from is copy, $to, :@mirrors-list) {
    given $from {
        when /\.git$/ {
            return git-fetch $from, $to;
        }
        when /^http '://'/ {
            #~ mkpath $to unless $to.IO.d;
            $to.IO.spurt: HTTP::UserAgent.new.get($from).content;
            CATCH {
                die "Could not fetch $from: {$_.message}"
            }
        }
        when /^cpan '://'/ {
            my $err;
            $from ~~ s[^cpan '://'] = '';
            mkpath ~$to unless $to.IO.d;
            for @mirrors-list -> $url {
                try {
                    my $target   = "$to/" ~ $from.match(/<-[/]>+$/);
                    my $meta_url = $from.subst(/'.tar.gz'$/, '.meta');
                    my $meta_to  = "$to/META.info";
                    $target.IO.spurt:  HTTP::UserAgent.new.get("$url/$from").content;
                    $meta_to.IO.spurt: HTTP::UserAgent.new.get("$url/$meta_url").content;
                    indir $target.path.directory, {
                        Archive::Tar.extract_archive( $target );
                    };
                    last;
                    CATCH {
                        $err = $!
                    }
                }
            }
            die "Could not fetch $from: {$err.message}" if $err ~~ Failure;
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
        my $d  = IO::Spec.catpath($io.volume, $io.directory, '');
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
