class Panda::Bundler;
use Panda::Common;
use Panda::Project;
use File::Find;

sub guess-project($where, Str :$name is copy, Str :$desc is copy) {
    my $source-url;

    indir $where, {
        if 'META.info'.IO.e {
            try my $json = from-json 'META.info'.IO.slurp;
            if $json {
                $name       = $json<name>        if !$name && $json<name>;
                $desc       = $json<description> if !$desc && $json<description>;
                $source-url = $json<source-url>  if $json<source-url>;
            }
        }
        unless $name {
            $name = $where.IO.parts<basename>.subst(/:i ^'p' 'erl'? '6-'/, '').split(/<[\-_]>+/, :g)>>.tc.join('::');
        }
        unless $desc {
            $desc = '.git/description'.IO.slurp if '.git/description'.IO.e
        }
        unless $source-url {
            try my $git = qx{git remote show origin}.lines.first(/\.git$/);
            if $git && $git ~~ /$<url>=\S+$/ {
                $source-url = $<url>;
                if $source-url ~~ m/'git@' $<host>=[.+] ':' $<repo>=[<-[:]>+] $/ {
                    $source-url = "git://$<host>/$<repo>"
                }
            }
        }
    };

    Panda::Project.new( :$name, :metainfo( :description($desc), :$source-url ) )
}

method bundle($panda, :$notests, Str :$name, Str :$auth, Str :$ver, Str :$desc) {
    my $dir  = $*CWD.absolute;
    my $bone = guess-project($dir, :$name, :$desc);

    my $perl6_exe = $*EXECUTABLE;
    try {
        my $*EXECUTABLE              = "$perl6_exe -MPanda::DepTracker";
        %*ENV<PANDA_DEPTRACKER_FILE> = "$dir/deptracker-build-$*PID";
        %*ENV<PANDA_PROTRACKER_FILE> = "$dir/protracker-build-$*PID";
        try unlink %*ENV<PANDA_DEPTRACKER_FILE> if %*ENV<PANDA_DEPTRACKER_FILE>.IO.e;
        try unlink %*ENV<PANDA_PROTRACKER_FILE> if %*ENV<PANDA_PROTRACKER_FILE>.IO.e;

        $panda.announce('building', $bone);
        unless $_ = $panda.builder.build($dir) {
            die X::Panda.new($bone.name, 'build', $_)
        }

        if "$dir/blib/lib".IO ~~ :d {
            find(dir => "$dir/blib/lib", type => 'file').list.grep( -> $lib is copy {
                next unless $lib.basename ~~ / \.pm 6? $/;
                $lib = file_to_symbol($lib);
                try shell "$*EXECUTABLE -Iblib/lib -M$lib -e1 " ~ ($*DISTRO.is-win ?? ' >NIL 2>&1' !! ' >/dev/null 2>&1');
            } )
        }

        if %*ENV<PANDA_DEPTRACKER_FILE>.IO.e {
            my $test = EVAL %*ENV<PANDA_DEPTRACKER_FILE>.IO.slurp;
            for $test.list -> $m {
                $bone.metainfo<build-depends>.push: $m<module_name> unless $m<file> ~~ /^"$dir" [ [\/|\\] blib ]? [\/|\\] lib [\/|\\]/ # XXX :auth/:ver/:from/...
            }
            %*ENV<PANDA_DEPTRACKER_FILE>.IO.spurt: ''
        }

        if %*ENV<PANDA_PROTRACKER_FILE>.IO.e {
            my $test = EVAL %*ENV<PANDA_PROTRACKER_FILE>.IO.slurp;
            for $test.list -> $m {
                for ($m<symbols> (-) $bone.metainfo<build-depends>).list.grep(/^<-[&]>*$/) {
                    if $m<file> && $m<file>.match(/^"$dir" [ [\/|\\] blib [\/|\\] ]? <?before 'lib' [\/|\\] > $<relname>=.+/) -> $match {
                        $bone.metainfo<build-provides>{$_ || file_to_symbol(~$match<relname>)} = ~$match<relname>
                    }
                }
            }
            %*ENV<PANDA_PROTRACKER_FILE>.IO.spurt: ''
        }

        unless $notests {
            $panda.announce('testing', $bone);
            unless $_ = $panda.tester.test($dir) {
                die X::Panda.new($bone.name, 'test', $_)
            }
            if %*ENV<PANDA_DEPTRACKER_FILE>.IO.e {
                my $test = EVAL %*ENV<PANDA_DEPTRACKER_FILE>.IO.slurp;
                for $test.list -> $m {
                    $bone.metainfo<test-depends>.push: $m<module_name> unless $m<file> ~~ /^"$dir" [ [\/|\\] blib ]? [\/|\\] lib [\/|\\]/ # XXX :auth/:ver/:from/...
                }
                $bone.metainfo<test-depends> = [$bone.metainfo<test-depends>.list.unique];
            }
            if %*ENV<PANDA_PROTRACKER_FILE>.IO.e {
                my $test = EVAL %*ENV<PANDA_PROTRACKER_FILE>.IO.slurp;
                for $test.list -> $m {
                    for ($m<symbols> (-) $bone.metainfo<build-depends>).list.grep(/^<-[&]>*$/) {
                        if $m<file> && $m<file>.match(/^"$dir" [ [\/|\\] blib [\/|\\] ]? <?before 'lib' [\/|\\] > $<relname>=.+/) -> $match {
                            $bone.metainfo<test-provides>{$_ || file_to_symbol(~$match<relname>)} = ~$match<relname>
                        }
                    }
                }
            }
        }

        unless $bone.name eq 'Panda' {
            $bone.metainfo<build-depends> = [($bone.metainfo<build-depends> (-) 'Panda::DepTracker').list.flat];
            $bone.metainfo<test-depends>  = [($bone.metainfo<test-depends>  (-) 'Panda::DepTracker').list.flat];
        }
        $bone.metainfo<depends>      = [($bone.metainfo<test-depends> (&) $bone.metainfo<build-depends>).list.flat];
        $bone.metainfo<test-depends> = [($bone.metainfo<test-depends> (-) $bone.metainfo<build-depends>).list.flat];
        for $bone.metainfo<test-provides>.kv, $bone.metainfo<build-provides>.kv -> $k, $v {
            $bone.metainfo<provides>{$k} = $v
        }

        $bone.metainfo<version> = $ver || prompt "Please enter version number (example: v0.1.0): ";

        $panda.announce('Creating META.info.proposed');
        'META.info.proposed'.IO.spurt: to-json({
            perl           => 'v6',
            name           => $bone.name,
            description    => $bone.metainfo<description>,
            version        => $bone.metainfo<version>,
            build-depends  => $bone.metainfo<build-depends>,
            test-depends   => $bone.metainfo<test-depends>,
            depends        => $bone.metainfo<depends>,
            provides       => $bone.metainfo<provides>,
            support        => {
                source => ~$bone.metainfo<source-url>,
            }
        }) ~ "\n";

        CATCH {
            try unlink %*ENV<PANDA_DEPTRACKER_FILE> if %*ENV<PANDA_DEPTRACKER_FILE>.IO.e;
            try unlink %*ENV<PANDA_PROTRACKER_FILE> if %*ENV<PANDA_PROTRACKER_FILE>.IO.e;
        }
    }

    try unlink %*ENV<PANDA_DEPTRACKER_FILE> if %*ENV<PANDA_DEPTRACKER_FILE>.IO.e;
    try unlink %*ENV<PANDA_PROTRACKER_FILE> if %*ENV<PANDA_PROTRACKER_FILE>.IO.e;

    return True;
}

sub file_to_symbol($file) {
    my @names = $file.IO.relative.subst(/ \.pm 6? $/, '').split(/<[\\\/]>/);
    shift @names if @names && @names[0] eq 'blib';
    shift @names if @names && @names[0] eq 'lib';
    @names.join('::');
}

# vim: ft=perl6
