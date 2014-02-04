#!/usr/bin/env perl6
use v6;
BEGIN {
    shell 'git submodule init';
    shell 'git submodule update';
}
use lib 'ext/File__Find/lib/';
use lib 'ext/Shell__Command/lib/';
use Shell::Command;

sub default-prefix {
    my $destdir = %*ENV<DESTDIR>;
    $destdir = "{cwd}/$destdir" if defined($destdir) && $*OS ne 'MSWin32' && $destdir !~~ /^ '/' /;
    for grep(*.defined, $destdir, %*CUSTOM_LIB<site home>) -> $prefix {
        $destdir  = "$prefix/panda";
        try mkpath $destdir;
        last if $destdir.path.w
    }
    unless $destdir.path.w {
        warn "destdir: { $destdir.perl }";
        die "Found no writable directory into which panda could be installed";
    }
    return $destdir;
}

sub MAIN(:$prefix = default-prefix()) {
    say "==> Bootstrapping Panda to $prefix";

    my $is_win = $*OS eq 'MSWin32';

    my $projects  = slurp 'projects.json.bootstrap';
       $projects ~~ s:g/_BASEDIR_/{cwd}\/ext/;
       $projects .= subst('\\', '/', :g) if $is_win;

    mkpath "$prefix/panda";
    given open "$prefix/panda/projects.json", :w {
        .say: $projects;
        .close;
    }

    my $env_sep = $is_win ?? ';' !! ':';

    %*ENV<PERL6LIB> ~= "{$env_sep}$prefix/lib";
    %*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/File__Find/lib";
    %*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/Shell__Command/lib";
    %*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/JSON__Tiny/lib";
    %*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/lib";
    %*ENV<DESTDIR> = "$prefix";

    my $pandapath;
    {
        my $pandabin = $prefix.IO.path.child('bin');
        mkpath $pandabin.Str;
        $pandapath = $pandabin.child('panda');
        'bin/panda'.path.copy($pandapath);
    }

    shell "$*EXECUTABLE_NAME $pandapath install File::Find Shell::Command JSON::Tiny {cwd}";
    say "==> Please make sure that $prefix/bin is in your PATH";

    unlink "$prefix/panda/projects.json";
}
