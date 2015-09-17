#!/usr/bin/env perl6
use v6;
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
    $prefix = "$CWD/$prefix" if defined($prefix) && $is_win && $prefix !~~ /^ '/' /;
    for grep(*.defined, flat $prefix, %*CUSTOM_LIB<site home>) -> $target {
        $prefix = $target;
        $panda-base = "$target/panda";
        try mkdir $prefix;
        try mkpath $panda-base unless $panda-base.IO ~~ :d;
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
      "$prefix/lib",
      "$CWD/ext/File__Find/lib",
      "$CWD/ext/Shell__Command/lib",
      "$CWD/ext/JSON__Fast/lib",
      "$CWD/lib",
    );

    my $prefix_str = $prefix ?? "--prefix=$prefix" !! '';
    shell "$*EXECUTABLE bin/panda $prefix_str install $*CWD";
    say "==> Please make sure that $prefix/bin is in your PATH";

    unlink "$panda-base/projects.json";
}
