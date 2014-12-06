#!/usr/bin/env perl6
use v6;
BEGIN {
    shell 'git submodule init';
    shell 'git submodule update';
}
use lib 'ext/File__Find/lib/';
use lib 'ext/Shell__Command/lib/';
use Shell::Command;
%*ENV<PANDA_SUBMIT_TESTREPORTS>:delete;

say '==> Bootstrapping Panda';

my $is_win = $*DISTRO.name eq 'mswin32';

my $panda-base;
my $destdir = %*ENV<DESTDIR>;
$destdir = "$*CWD/$destdir" if defined($destdir) && $*OS ne 'MSWin32' && $destdir !~~ /^ '/' /;
for grep(*.defined, $destdir, %*CUSTOM_LIB<site home>) -> $prefix {
    $destdir  = $prefix;
    $panda-base = "$prefix/panda";
    try mkdir $destdir;
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

my $env_sep = $is_win ?? ';' !! ':';

%*ENV<RAKUDOLIB> = "$destdir.^name()=$destdir" if $destdir.^can('install');
%*ENV<PERL6LIB> ~= "{$env_sep}$destdir/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}$*CWD/ext/File__Find/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}$*CWD/ext/Shell__Command/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}$*CWD/ext/JSON__Tiny/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}$*CWD/lib";

shell "$*EXECUTABLE bin/panda install File::Find Shell::Command JSON::Tiny $*CWD";
if "$destdir/panda/src".IO ~~ :d {
    rm_rf "$destdir/panda/src"; # XXX This shouldn't be necessary, I think
                                # that src should not be kept at all, but
                                # I figure out how to do that nicely, let's
                                # at least free boostrap from it
}
say "==> Please make sure that $destdir/bin is in your PATH";

unlink "$panda-base/projects.json";
