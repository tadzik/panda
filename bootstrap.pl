#!/usr/bin/env perl6
use v6;
BEGIN {
    shell 'git submodule init';
    shell 'git submodule update';
}
use lib 'ext/File__Find/lib/';
use lib 'ext/Shell__Command/lib/';
use Shell::Command;

say '==> Bootstrapping Panda';

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
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/File__Find/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/Shell__Command/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/JSON__Tiny/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/DateTime__Parse/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/HTTP__Status/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/Encode/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/File__Temp/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/MIME__Base64/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/IO__Capture__Simple/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/HTTP__UserAgent/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/NativeCall/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/Compress__Zlib__Raw/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/Compress__Zlib/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/Archive__Tar/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/lib";

shell "$*EXECUTABLE bin/panda install File::Find Shell::Command JSON::Tiny DateTime::Parse HTTP::Status Encode File::Temp MIME::Base64 IO::Capture::Simple HTTP::UserAgent NativeCall Compress::Zlib::Raw Compress::Zlib Archive::Tar {cwd}";
if "$destdir/panda/src".IO ~~ :d {
    rm_rf "$destdir/panda/src"; # XXX This shouldn't be necessary, I think
                                # that src should not be kept at all, but
                                # I figure out how to do that nicely, let's
                                # at least free boostrap from it
}
say "==> Please make sure that $destdir/bin is in your PATH";

unlink "$panda-base/projects.json";
