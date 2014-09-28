class Panda::Fetcher;
use Panda::Common;
use File::Find;
use Shell::Command;
use HTTP::UserAgent :simple;
use Compress::Zlib;
use Archive::Tar;

method fetch($from is copy, $to, :@mirrors-list) {
    given $from {
        when /\.git$/ {
            return git-fetch $from, $to;
        }
        when *.IO.d {
            local-fetch $from, $to;
        }
        when /^http '://'/ {
            #~ mkpath $to unless $to.IO.d;
            getstore($from, ~$to);
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
                    getstore("$url/$from",     $target);
                    getstore("$url/$meta_url", $meta_to);
                    say "ls -l $target";
                    shell("ls -l $target");
                    shell("ls -l $meta_to");
                    indir $target.path.directory, {
                        Archive::Tar.extract_archive( $target );
                    };
                    shell("ls -l $target.path.directory()");
                    #~ gzslurp($target);
                    last;
                    CATCH {
                        $err = $!
                    }
                }
            }
            die "Could not fetch $from: {$err.message}" if $err ~~ Failure;
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
    my $cleanup       = $from.IO.path.cleanup;
    my $cleanup_chars = $cleanup.chars;
    for eager find(dir => $from).list {
        my $d = IO::Spec.catpath($_.volume, $_.directory, '');
        # We need to cleanup the path, because the returned elems are too.
        if ($d.Str.index(~$cleanup) // -1) == 0 {
            $d = $d.substr($cleanup_chars)
        }

        next if $d ~~ /^ '/'? '.git'/; # skip VCS files
        my $where = "$to/$d";
        mkpath $where;
        next if $_.IO ~~ :d;
        $_.copy("$where/{$_.basename}");
    }
    return True;
}

# vim: ft=perl6
