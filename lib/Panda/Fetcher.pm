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
          and fail "Failed cloning git repository '$from'";
    return True;
}

sub local-fetch($from, $to) {
    for find(dir => $from).list {
        my $d = $_.directory.substr($from.chars);
        next if $d ~~ /^ '/'? '.git'/; # skip VCS files
        my $where = "$to/$d";
        mkpath $where;
        next if $_.IO ~~ :d;
        $_.copy("$where/{$_.basename}");
    }
    return True;
}

# vim: ft=perl6
