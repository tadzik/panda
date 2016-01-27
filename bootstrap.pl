#!/usr/bin/env perl6
use v6;
use v6.c;
use lib 'ext/File__Find/lib/';
use lib 'ext/Shell__Command/lib/';
use Shell::Command;

sub MAIN(Str :$prefix is copy) {
    say '==> Bootstrapping Panda';

    # prevent a lot of expensive dynamic lookups
    my $CWD    := $*CWD;
    my $DISTRO := $*DISTRO;
    my %ENV    := %*ENV;

    %ENV<PANDA_SUBMIT_TESTREPORTS>:delete;

    my $is_win = $DISTRO.is-win;

    my $panda-base;
    my $repo;
    $prefix = "$CWD/$prefix" if defined($prefix) && $is_win && $prefix !~~ /^ '/' /;
    my @repos = $*REPO.repo-chain.grep(CompUnit::Repository::Installable).grep(*.can-install);
    my @custom-lib = <site home>.map({CompUnit::RepositoryRegistry.repository-for-name($_)});
    for grep(*.defined, flat $prefix, @custom-lib, @repos) -> $target {
        if $target ~~ CompUnit::Repository {
            $prefix = $target.path-spec;
            $repo   = $prefix;
            $panda-base = "{$target.prefix}/panda";
            try mkdir $panda-base unless $panda-base.IO.d;
        }
        else {
            $prefix = $target;
            $repo   = "$target/lib";
            $panda-base = "$target/panda";
            try mkdir $prefix;
            try mkpath $panda-base unless $panda-base.IO ~~ :d;
        }
        last if $panda-base.IO.w
    }
    unless $panda-base.IO.w {
        warn "panda-base: { $panda-base.perl }";
        die "Found no writable directory into which panda could be installed";
    }

    my $projects  = slurp 'projects.json.bootstrap';
       $projects ~~ s:g/_BASEDIR_/$*CWD\/ext/;
       $projects .= subst('\\', '/', :g) if $is_win;

    given open "$panda-base/projects.json", :w {
        .say: $projects;
        .close;
    }

    my $env_sep = $DISTRO.?cur-sep // $DISTRO.path-sep;

    %ENV<PERL6LIB>  = join( $env_sep,
      "file#$CWD/ext/File__Find/lib",
      "file#$CWD/ext/Shell__Command/lib",
      "file#$CWD/ext/JSON__Fast/lib",
      "file#$CWD/lib",
      $repo,
    );

    my $prefix_str = $prefix ?? "--prefix=$prefix" !! '';
    shell "$*EXECUTABLE --ll-exception bin/panda --force $prefix_str install $*CWD";
    $prefix = $prefix.substr(5) if $prefix.starts-with("inst#");
    say "==> Please make sure that $prefix/bin is in your PATH";

    unlink "$panda-base/projects.json";
}

# vim: ft=perl6
