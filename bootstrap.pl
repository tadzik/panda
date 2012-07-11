use v6;

%*ENV<PERL6LIB> = "{%*ENV<PERL6LIB>}:{cwd}/ext:{cwd}/lib";
shell "perl6 bin/panda install File::Tools JSON::Tiny Test::Mock";
shell "perl6 bin/panda install .";
