use v6;

my $home = $*OS eq 'MSWin32' ?? %*ENV<HOMEDRIVE> ~ %*ENV<HOMEPATH> !! %*ENV<HOME>;

mkdir $home unless $home.IO.d;
mkdir "$home/.panda" unless "$home/.panda".IO.d;
my $projects = slurp 'projects.json.bootstrap';
$projects ~~ s:g/_BASEDIR_/{cwd}\/ext/;
given open "$home/.panda/projects.json", :w {
    .say: $projects;
    .close;
}

my $oldenv  = %*ENV<PERL6LIB> // '';
my $env_sep = $*VM<config><osname> eq 'MSWin32' ?? ';' !! ':';


if %*ENV<DESTDIR> {
    %*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/{%*ENV<DESTDIR>}/lib"
}

%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/File__Tools/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/JSON__Tiny/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/ext/Test__Mock/lib";
%*ENV<PERL6LIB> ~= "{$env_sep}{cwd}/lib";

shell "perl6 bin/panda install File::Tools JSON::Tiny Test::Mock";

%*ENV<PERL6LIB> = join $env_sep, $oldenv, cwd() ~ '/lib';

shell "perl6 bin/panda install .";

unlink "$home/.panda/projects.json";
