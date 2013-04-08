class Panda::Fetcher;
use File::Find;
use Shell::Command;

method fetch($from, $to) {
    given $from {
        when /\.git$/ {
            git-fetch $from, $to;
        }
        when *.IO.d {
            local-fetch $from, $to;
        }
        default {
            die "Unable to handle source '$from'"
        }
    }
}

sub git-fetch($from, $to) {
    shell "git clone -q $from \"$to\""
          and die "Failed cloning git repository '$from'"
}

sub local-fetch($from, $to) {
    for find(dir => $from).list {
        my $d = $_.dir.substr($from.chars);
        next if $d ~~ /^ '/'? '.git'/; # skip VCS files
        my $where = "$to/$d";
        mkpath $where;
        next if $_.IO ~~ :d;
        $_.IO.copy("$where/{$_.name}");
    }
}

# vim: ft=perl6
