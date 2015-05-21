#!/usr/bin/env perl6
use v6;
use lib 'ext/File__Find/lib/';
use lib 'ext/Shell__Command/lib/';
use Shell::Command;

say '==> Bootstrapping Panda';

# prevent a lot of expensive dynamic lookups
my $CWD    := $*CWD;
my $DISTRO := $*DISTRO;
my %ENV    := %*ENV;

%ENV<PANDA_SUBMIT_TESTREPORTS>:delete;

my $is_win = $DISTRO.is-win;

my $panda-base;
my $destdir;
# $path-spec can be an absolute or relative path (which will defautl to a CompUnitRepo::Local::File),
# or it is preceeded by 'inst#' or 'file#' which will choose the CompUnitRepo with this short-id.
for grep(*.defined, %ENV<DESTDIR>, %*CUSTOM_LIB<site home>) -> $path-spec {
    $destdir    = CompUnitRepo.new($path-spec);
    $panda-base = $destdir.IO.child('panda');
    try mkpath ~$panda-base; # IO::Path caches filestats, so we stringify here otherwise the .w check will fail
    last if $panda-base.w;
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
  "$destdir/lib", # Eventually should be: $destdir.path-spec
  "file#$CWD/ext/File__Find/lib",
  "file#$CWD/ext/Shell__Command/lib",
  "file#$CWD/ext/JSON__Tiny/lib",
  "file#$CWD/lib",
);

shell "$*EXECUTABLE bin/panda --rebuild=False install File::Find Shell::Command JSON::Tiny $*CWD";
if "$destdir/panda/src".IO ~~ :d {
    rm_rf "$destdir/panda/src"; # XXX This shouldn't be necessary, I think
                                # that src should not be kept at all, but
                                # I figure out how to do that nicely, let's
                                # at least free boostrap from it
}
say "==> Please make sure that $destdir/bin is in your PATH";

unlink "$panda-base/projects.json";
