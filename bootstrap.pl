#!/usr/bin/env perl6
use v6;

say '==> Bootstrapping Panda';

my $is_win = $*OS eq 'MSWin32';

my $panda-base;
my $destdir = %*ENV<DESTDIR>;
$destdir = "{cwd}/$destdir" if defined($destdir) && $*OS ne 'MSWin32' && $destdir !~~ /^ '/' /;
for grep(*.defined, $destdir, %*CUSTOM_LIB<site home>) -> $prefix {
    $destdir  = $prefix;
    $panda-base = "$prefix/panda";
    try mkdir $destdir;
    try mkdir $panda-base unless $panda-base.IO ~~ :d;
    last if $panda-base.path.w
}
unless $panda-base.path.w {
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

shell "perl6 bin/panda install File::Tools JSON::Tiny Test::Mock {cwd}";

say "==> Please make sure that $destdir/bin is in your PATH";

unlink "$panda-base/projects.json";
