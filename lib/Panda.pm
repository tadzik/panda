unit class Panda;
use Module::Toolkit;
#use Panda::Bundler;
#use Panda::Reporter;
use Panda::Exceptions;
use Shell::Command;
use JSON::Fast;
use File::Temp;

has $.workdir = $*CWD.child('.panda-work');
has $.toolkit
    handles <get-project dist-from-location project-list
             is-installed get-dependencies fetch test install>
    = Module::Toolkit.new;
#has $.bundler = Panda::Bundler.new;

method tmpdir() {
    LEAVE rm_rf $!workdir;
    my $ret = tempdir(:tempdir($!workdir), :!unlink);
    mkpath $ret;
    $ret.IO;
}

multi method announce(Str $what) {
    say "==> $what"
}

multi method announce('fetching', Distribution $p) {
    self.announce: "Fetching {$p.name}"
}

multi method announce('building', Distribution $p) {
    self.announce: "Building {$p.name}"
}

multi method announce('testing', Distribution $p) {
    self.announce: "Testing {$p.name}"
}

multi method announce('installing', Distribution $p) {
    self.announce: "Installing {$p.name}"
}

multi method announce('success', Distribution $p) {
    self.announce: "Successfully installed {$p.name}"
}

multi method announce('depends', Distribution $p, @deps) {
    self.announce: "{$p.name} depends on {@deps».name.join(", ")}"
}

method suggest($name) {
    my &canonical = *.subst(/ <[\- _ :]>+ /, "", :g).lc;
    my $cpname = canonical($name);
    my @suggestions;
    for self.project-list.map(*.name) {
        @suggestions.push($_) if canonical($_) eq $cpname;
    }

    if @suggestions.elems == 1 {
        return "Maybe you meant {@suggestions[0]}?"
    } elsif @suggestions.elems > 1 {
        return "Maybe you meant any of: {@suggestions.join(", ")}?"
    }
}

method look(Distribution $bone) {
    my $dir = self.tmpdir();

    self.announce('fetching', $bone);
    try {
        self.fetch($bone, $dir);
        CATCH { default {
            die X::Panda.new($bone.name, 'fetch', $_.message)
        }}
    }

    my $shell = %*ENV<SHELL>;
    $shell ||= %*ENV<ComSpec>
        if $*DISTRO.is-win;

    if $shell {

        my $*CWD = $dir;
        self.announce("Entering $dir with $shell\n");
        shell $shell or fail "Unable to invoke shell: $shell"
    } else {
        self.announce("You don't seem to have a SHELL");
    }
}

method !check-perl-version(Distribution $bone) {
    if $bone.?perl -> $perl-version-str is copy {
        note "Please remove leading 'v' from perl version in {$bone.Str}'s meta info."
            if $perl-version-str ~~ s/^v//; # remove superfluous leading "v"
        my $perl-version = Version.new($perl-version-str);
        use MONKEY-SEE-NO-EVAL;
        my Bool $supported = try { EVAL "use { $perl-version.gist }"; True };
        die "$bone requires Perl version $perl-version-str. Cannot continue."
            unless $supported;
    }
}

#= fetches, tests and installs a single distribution
#= C<$notests> -- don't attempt testing at all
#= C<$force>   -- install regardless of test results and currently
#=                installed version
#= C<$update>  -- install even if the same version is installed
#= C<$verbose> -- don't surpress test output
method resolve-one(Distribution $dist,
                   Bool() :$notests,
                   Bool() :$force,
                   Bool() :$update,
                   Bool() :$verbose) {

    sub test($dir) {
        if $verbose {
            self.test($dir, output => $*OUT)
        } else {
            self.test($dir)
        }
    }

    my $tmpdir = self.tmpdir();
    self.announce('fetching', $dist);
    self.fetch($dist, $tmpdir);
    unless $notests {
        self.announce('testing', $dist);
        unless test($tmpdir) or $force {
            die X::Panda.new($dist.name, 'test');
        }
    }
    self.announce('installing', $dist);
    self.install($tmpdir, :force($force or $update));
    self.announce('success', $dist);

    #XXX ADDME
    #my $reports-file = ($.ecosystem.statefile.IO.dirname
    #                    ~ '/reports.' ~ $*PERL.compiler.version).IO;
    #Panda::Reporter.new( :$bone, :$reports-file ).submit;
}

#= fetches, tests and installs a distribution with its dependencies
#= (unless othewise specified)
#=
#= C<$nodeps>  -- don't calculate or install dependencies
#= C<$notests> -- don't attempt testing at all
#= C<$force>   -- install regardless of test results and currently
#=                installed version
#= C<$update>  -- install even if the same version is installed
#= C<$verbose> -- don't surpress test output
method resolve(Str   $name,
               Bool :$notests = False,
               Bool :$nodeps  = False,
               Bool :$force   = False,
               Bool :$update  = False,
               Bool :$verbose = False) {

    sub resolve(Distribution $target) {
        self.resolve-one($target, :$notests, :$force,
                                  :$verbose, :$update)
    }

    sub should-skip(Distribution $target) {
        !$force and !$update and self.is-installed($target);
    }

    my $dist = self.get-project($name);
    unless $dist {
        my $tmpdir = self.tmpdir;
        $dist = self.dist-from-location($name, $tmpdir);
        if $name !~~ rx{'/'|'.'|'\\'} {
            die X::Panda.new($name, 'resolve',
                    "Possibly ambiguous module name requested." 
                    ~ " Please specify at least one slash"
                    ~ " if you really mean to install"
                    ~ " from local directory (e.g. ./$name)")
        }
        if $dist {
            self.announce: "Installing {$dist.name} "
                         ~ "from a custom location $name";
        } else {
            my $suggestion = self.suggest($name) // '';
            die X::Panda.new(
                $name, 'resolve',
                "Project $name not found in the ecosystem. "
                ~ $suggestion);
        }
    }
    if should-skip($dist) {
        self.announce: "{$dist.name} is already installed";
        return;
    }
    unless $nodeps {
        my @deps = self.get-dependencies($dist);
        self.announce('depends', $dist, @deps) if +@deps;
        for @deps -> $dep {
            if should-skip($dep) {
                self.announce: "{$dep.name} is already installed";
                next;
            }
            &resolve($dep);
            CATCH {
                when X::Panda {
                    die X::Panda.new(
                        $name, 'resolve',
                        "Dependencies for {$dist.name} "
                      ~ "could not be installed");
                }
            }
        }
    }
    &resolve($dist);
}

method listprojects(:$installed, :$verbose) {
    my @projects  = self.project-list.sort(*.name.lc);
       @projects .= grep({ self.is-installed($_) }) if $installed;
#    my @saved     = @projects.flatmap({ $es.project-get-saved-meta($_) || {} });
    my $max-name  = @projects».name».chars.max;
    my $max-ver   = @projects».version».chars.max;
    #my $max-rev   = @saved.flatmap({ $_<source-revision> // '?'})».chars.max;

    for @projects -> $x {
        my $tag = self.is-installed($x) ?? '[installed]' !! '';

        #my $meta = $s ?? $es.project-get-saved-meta($x) !! $x.metainfo;
        my $url  = $x.source-url
                // $x.support<source>
                // 'UNKNOWN';
        #my $rev  = $meta<source-revision> // '?';
        my $ver  = $x.version;

        if ($verbose) {
            printf "%-{$max-name}s  %-12s  %-{$max-ver}s  %s\n",
                   $x.name, $tag, $ver, $url;
        }
        else {
            printf "%-{$max-name}s  %-12s\n", $x.name, $tag;
        }
    }
}

method search-projects($string) {
    sub wrap ($str) is export {
        return $str.comb(/ . ** 0..40 [ << | $ ]/)\
                   .grep({ .chars > 0 })\
                   .join("\n" ~ " " x 36);
    }

    for self.project-list -> $p {
        next unless $p.name ~~ /:i $string / || $p.description ~~ /:i $string /;
        printf "%-24s %-10s %s\n",
               $p.name, $p.version, wrap($p.description);
    }
}

method projectinfo(@args) {
    for @args -> $p {
        my $x = self.get-project($p);
        $x = self.dist-from-location($p) unless $x;
        if $x {
            my $state = self.is-installed($x) ?? 'installed' !! '';
            my $installed;
            if False and $state ~~ 'installed' {
                #$installed = self.project-get-saved-meta($x);
            }
            print $x.name;
            if $x.version ne '*' {
                my $foo = '';
                if $installed {
                    $foo = " available, {$installed.version} installed"
                }
                say " (version {$x.version}$foo)";
            } else {
                say ''
            }
            if my $d = $x.description {
               say $d
            }
            say 'Depends on: ', $x.depends.join(', ')
                if $x.depends;
            print 'State: ';
            given $state {
                when 'installed'     {
                    say 'installed';
                }
                default {
                    say 'not installed'
                }
            }
            for $x.hash.kv -> $k, $v {
                say "{$k.tc}: $v"
                    if $v
                    and $k ~~ none(<version name depends description>);
            }
        } else {
            say "Project '$p' not found"
        }
    }
}

# vim: ft=perl6
