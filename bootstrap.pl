#!/usr/bin/env perl6
use v6;
use lib 'ext/File__Tools/lib/';
use Shell::Command;

say '==> Bootstrapping Panda';

run 'git submodule update';

my $is_win = $*OS eq 'MSWin32';

my $panda-base;
my $destdir = %*ENV<DESTDIR>;
$destdir = "{cwd}/$destdir" if defined($destdir) && $*OS ne 'MSWin32' && $destdir !~~ /^ '/' /;
for grep(*.defined, $destdir, %*CUSTOM_LIB<site home>) -> $prefix {
    $destdir  = $prefix;
    $panda-base = "$prefix/panda";
    try mkdir $destdir;
    try mkpath $panda-base unless $panda-base.IO ~~ :d;
    last if $panda-base.path.w
}
unless $panda-base.path.w {
    warn "panda-base: { $panda-base.perl }";
    die "Found no writable directory into which panda could be installed";
}

my $projects  = slurp 'projects.json.bootstrap';
   $projects ~~ s:g/_BASEDIR_/{cwd}\/ext/;
   $projects .= subst('\\', '/', :g) if $is_win;

given open "$panda-base/projects.json", :w {
    .say: $projects;
    .close;
}

my $env_sep = $is_win ?? ';' !! ':';

%*ENV<PERL6LIB> ~= "{$env_sep}$destdir/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/File__Tools/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/JSON__Tiny/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/Test__Mock/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/lib";

shell "perl6 bin/panda install File::Tools JSON::Tiny {cwd}";

say "==> Please make sure that $destdir/bin is in your PATH";

unlink "$panda-base/projects.json";
