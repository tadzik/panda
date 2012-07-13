use v6;

my $oldenv  = %*ENV<PERL6LIB> // '';
my $env_sep = $*VM<config><osname> eq 'MSWin32' ?? ';' !! ':';
%*ENV<PERL6LIB> = join $env_sep, $oldenv, cwd() ~ '/ext', cwd() ~ '/lib';
shell "perl6 bin/panda install File::Tools JSON::Tiny Test::Mock";
%*ENV<PERL6LIB> = join $env_sep, $oldenv, cwd() ~ '/lib';
shell "perl6 bin/panda install .";
