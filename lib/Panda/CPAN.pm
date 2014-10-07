class Panda::CPAN {
    has $.pandadir;
    has @.p6dists;

    use Panda::Project;
    use Compress::Zlib;

    method update($panda, :$force) {
        for < p6dists.json    p6dists.json.gz
              p6provides.json p6provides.json.gz
              p6binaries.json p6binaries.json.gz > -> $json, $gz {
            my $io = "$!pandadir/$gz".IO;
            if $force || !$io.s || 0 < $io.modified < now - 86400 {
                my $i = 0;
                for $panda.mirrors.urls($panda) -> $url {
                    $i ?? $panda.announce("Retrying $url/authors/$gz")
                       !! $panda.announce("Fetching $url/authors/$gz");
                    try $panda.fetcher.fetch: "$url/authors/$gz", "$!pandadir/$gz";
                    say $!.message if $!;
                    if "$!pandadir/$gz".IO.s { # }
                        "$!pandadir/$json".IO.spurt: gzslurp("$!pandadir/$gz");
                        last;
                    }
                    $i++;
                }
            }
        }
    }

    method p6dists {
        unless @!p6dists {
            my $json = from-json "$!pandadir/p6dists.json".IO.slurp;
            for $json.list {
                my ($tarball, $dist) = .kv;
                my $p = Panda::Project.new(
                    name         => $dist<name>,
                    auth         => $dist<auth>,
                    version      => Version.new($dist<ver> eq '*' ?? 0 !! $dist<ver>),
                    dependencies => [],
                    metainfo     => {
                        description => '',
                        source-url  => "cpan://authors/id/$tarball",
                    },
                );
                @!p6dists.push: $p;
            }
        }
        @!p6dists
    }

    method get-project($p as Str) {
        @.p6dists.grep({ $^a.name eq $p }).sort({ $^b.version cmp $^a.version })[0]
    }
}

# vim: ft=perl6
