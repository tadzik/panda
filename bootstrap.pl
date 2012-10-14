#!/usr/bin/env perl6
use v6;

say '==> Bootstrapping Panda';

my $is_win = $*OS eq 'MSWin32';
my $panda-base = "$*CUSTOM-LIB/panda";
mkdir $*CUSTOM-LIB unless $*CUSTOM-LIB.path.d;
mkdir $panda-base  unless $panda-base.path.d;

my $projects  = slurp 'projects.json.bootstrap';
   $projects ~~ s:g/_BASEDIR_/{cwd}\/ext/;
   $projects .= subst('\\', '/', :g) if $is_win;

given open "$panda-base/projects.json", :w {
    .say: $projects;
    .close;
}

my $env_sep = $is_win ?? ';' !! ':';
my $destdir = %*ENV<DESTDIR> || $*CUSTOM-LIB;
   $destdir = "{cwd}/$destdir" unless $destdir ~~ /^ '/' /
                                   || $is_win && $destdir ~~ /^ [ '\\' | <[a..zA..Z]> ':' ] /;

%*ENV<PERL6LIB> ~= "{$env_sep}$destdir/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/File__Tools/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/JSON__Tiny/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/Test__Mock/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/lib";

shell "perl6 bin/panda install File::Tools JSON::Tiny Test::Mock {cwd}";

unlink "$panda-base/projects.json";
