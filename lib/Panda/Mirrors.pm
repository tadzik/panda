class Panda::Mirrors {
    has $.mirrorsfile;
    has $.mirrorslist;
    has $.url = 'http://www.cpan.org/MIRRORED.BY';

    #~ use JSON::Tiny;

    method update($panda, :$force) {
        my $io = $!mirrorsfile.IO;
        if $force || !$io.s || 0 < $io.modified < now - 86400 {
            $panda.announce("Fetching $!url");
            $panda.fetcher.fetch: $!url, $!mirrorsfile;
        }
    }

    method probe($panda, $limit = Inf) {
        self.update($panda);

        my grammar Ping {
            rule TOP {
                .+? <timing>+
            }
            rule timing {
                'time=' <number> <unit>
            }
            token number {
                <[\d\.]>+
            }
            token unit {
                | ms
            }
        }

        my class Ping::Average {
            method TOP($/) {
                make ([+] $<timing>».made) / $<timing>.elems
            }
            method timing($/) {
                make $<number>.made * $<unit>.made
            }
            method number($/) {
                make ~$/
            }
            method unit($/) {
                given ~$/ {
                    make 1/1000 when 'ms';
                    make 1      when 's';
                }
            }
        }

        my %data;
        my $key;

        for $!mirrorsfile.IO.lines {
            when /^ \s* '#'/ {
                next
            }
            when /^ \s* (\S+) \s* ':' \s* $/ {
                $key = $0;
            }
            when /^ \s* (\S+?) \s* '=' \s* \" (<-[\"]>*) \" \s* $/ {
                %data{$key}{$0} = "$1";
            }
            when /\S/ {
                try unlink $!mirrorsfile;
                die "Failed to parse mirrorlist. Offending line was:\n$_"
            }
        }

        $panda.announce("Pinging {+%data.keys} servers, please be patient");
        my $x = 0;
        for %data.kv -> $name, $values is rw {
            $values<ping> = Inf;
            if ($x++ < $limit && $values<dst_http> // $values<dst_ftp>) ~~ m,^ \w+ '://' $<host>=<-[/]>+ , {
                $values<ping> = Ping.subparse(qqx{ping -n -c1 -W1 $<host>}, :actions(Ping::Average)).?made // Inf
            }
        }

        $panda.announce("Saving top 10 to $!mirrorslist");
        my @top10 = %data.sort(*.value<ping> <=> *.value<ping>)[^10];
        given open($!mirrorslist, :w) {
            .say: to-json(@top10);
            .close;
        }

        #~ CATCH {
            #~ die "Could not probe mirrors: {$_.message}"
        #~ }
    }

    method urls($panda) {
        self.probe($panda, 30) unless $!mirrorslist.IO.s;

        my $json = from-json $!mirrorslist.IO.slurp;
        $json.map(*.values[0].<dst_http>).grep(*.defined)>>.subst(/'/'$/, '')
    }
}

# vim: ft=perl6
