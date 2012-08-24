#!/usr/bin/env perl6
use v6;

say '==> Bootstrapping Panda';

my $is_win = $*OS eq 'MSWin32';
my $home   = $is_win ?? %*ENV<HOMEDRIVE> ~ %*ENV<HOMEPATH> !! %*ENV<HOME>;

mkdir  $home         unless  $home.IO.d;
mkdir "$home/.panda" unless "$home/.panda".IO.d;

my $projects  = slurp 'projects.json.bootstrap';
   $projects ~~ s:g/_BASEDIR_/{cwd}\/ext/;
   $projects .= subst('\\', '/', :g) if $is_win;

given open "$home/.panda/projects.json", :w {
    .say: $projects;
    .close;
}

my $env_sep = $is_win ?? ';' !! ':';
my $destdir = %*ENV<DESTDIR> || "$home/.perl6";
   $destdir = "{cwd}/$destdir" unless $destdir ~~ /^ '/' /
                                   || $is_win && $destdir ~~ /^ [ '\\' | <[a..zA..Z]> ':' ] /;

%*ENV<PERL6LIB> ~= "{$env_sep}$destdir/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/File__Tools/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/JSON__Tiny/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/Test__Mock/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/lib";

shell "perl6 bin/panda install File::Tools JSON::Tiny Test::Mock {cwd}";

unlink "$home/.panda/projects.json";
