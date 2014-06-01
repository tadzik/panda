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
        when /^http '://'/ {
            http-fetch $from, $to;
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

sub http-fetch($from, $to) {
    my $s;
    my $host = $from ~~ /^ [\w+ '://']? $<host>=[ <-[\/]>+ ] / ?? ~$<host> !! die "Could not parse url '$from'";
    if  %*ENV<http_proxy> {
        my ($host, $port) = %*ENV<http_proxy>.split('/').[2].split(':');
        $s = IO::Socket::INET.new(host => $host, port => $port.Int);
    }
    else {
        $s = IO::Socket::INET.new(:$host, :port(80));
    }
    $s.send("GET $from HTTP/1.1\nHost: $host\nAccept: */*\nConnection: Close\n\n");
    my $buf = $s.recv(:bin);

    my $i = 0;
    my ($header, $new_chunk) = $buf.decode('utf8').split(/\r\n\r\n/, 2);
    my @chunks = $new_chunk.encode;
    if $header ~~ /^^ 'Transfer-Encoding:' \N+ chunked / {
        my ($size, $new_chunk) = @chunks[$i].decode('utf8').split(/\r?\n/, 2);
        @chunks[$i] = $new_chunk.encode;
        $size = :16($size);
        while @chunks[$i].bytes < $size {
            @chunks[$i] ~= $s.recv(:bin, $size - @chunks[$i].bytes);
            
            if $size == @chunks[$i].bytes {
                $i++;
                @chunks[$i] ~= $s.recv(10, :bin).decode('utf8').trim-leading;
                ($size, $new_chunk) = @chunks[$i].split(/\r?\n/, 2);
                @chunks[$i] = $new_chunk.encode;
                $size = :16($size);
            }
        }
    }

    given open($to, :w) {
        .say: @chunks>>.decode('utf8').join('');
        .close;
    }

    CATCH {
        die "Could not download mirrors list: {$_.message}"
    }
}

# vim: ft=perl6
