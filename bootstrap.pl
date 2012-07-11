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

%*ENV<PERL6LIB> ~= ":{cwd}/ext/File__Tools/lib";
%*ENV<PERL6LIB> ~= ":{cwd}/ext/JSON__Tiny/lib";
%*ENV<PERL6LIB> ~= ":{cwd}/ext/Test__Mock/lib";
%*ENV<PERL6LIB> ~= ":{cwd}/lib";
shell "perl6 bin/panda install File::Tools JSON::Tiny Test::Mock";
shell "perl6 bin/panda install .";

unlink "$home/.panda/projects.json";
