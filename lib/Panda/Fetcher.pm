class Panda::Fetcher;
use File::Find;
use Shell::Command;

method fetch($from, $to) {
    given $from {
        when /\.git$/ {
            return git-fetch $from, $to;
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
    for find(dir => $from).list {
        my $d = IO::Spec.catpath($_.volume, $_.directory, '');
        # We need to cleanup the path, because the returned elems are too.
        my $cleanup = $from.IO.path.cleanup;
        if $d.match(/^$cleanup/) {
            $d = $d.substr($cleanup.chars)
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
