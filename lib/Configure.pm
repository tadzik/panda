# Configure.pm

.say for
    '',
    'Configure.pm is preparing to make your Makefile.',
    '';

# Determine how this Configure.p6 was invoked, to write the same paths
# and executables into the Makefile variables. The variables are:
# PERL6       how to execute a Perl 6 script
# PERL6LIB    initial value of @*INC, where 'use <module>;' searches
# PERL6BIN    directory where executables such as 'prove' reside
# RAKUDO_DIR  (deprecated) currently the location of Rakudo's Test.pm

my $parrot_dir = %*VM<config><build_dir>;
my $rakudo_dir;
my $perl6;

regex parrot_in_rakudo { ( .* '/rakudo' ) '/parrot' }

# There are two possible relationships between the parrot and rakudo
# directories: rakudo/parrot or parrot/languages/rakudo
if $parrot_dir ~~ / <parrot_in_rakudo> / {
    # first case, rakudo/parrot for example if installed using new
    # 'git clone ...rakudo.git' then 'perl Configure.pl --gen-parrot'
    $rakudo_dir = $parrot_dir.subst( / '/parrot' $ /, ''); #'
}
elsif "$parrot_dir/languages/rakudo" ~~ :d {
    # second case, parrot/languages/rakudo if installed the old way
    $rakudo_dir = "$parrot_dir/languages/rakudo";
}
else { # anything else 
    .say for
        "Found a PARROT_DIR to be $parrot_dir",
        'but there is no Rakudo nearby. Please contact the proto people.',
        '';
    exit(1);
}
if "$rakudo_dir/perl6" ~~ :f or "$rakudo_dir/perl6.exe" ~~ :f {
    $perl6 = "$rakudo_dir/perl6";  # the fake executable from pbc_to_exe
}
else {
    $perl6 = "$parrot_dir/parrot $rakudo_dir/perl6.pbc";
}

say "PERL6       $perl6";
my $perl6lib = %*ENV<PERL6LIB>
                ?? %*ENV<PERL6LIB> ~ ':' ~ %*ENV<PWD> ~ '/lib'
                !! %*ENV<PWD> ~ '/lib';
say "PERL6LIB    $perl6lib";
# The perl6-examples/bin directory is a sibling of PERL6LIB
my $perl6bin = $perl6lib.subst( '/lib', '/bin' );
say "PERL6BIN    $perl6bin";
say "RAKUDO_DIR  $rakudo_dir";

# Read Makefile.in, edit, write Makefile
my $maketext = slurp( 'Makefile.in' );
$maketext .= subst( .key, .value ) for
    'Makefile.in'       => 'Makefile',
    'To be read'        => 'Written',
    'replaces <TOKENS>' => 'defined these',
# Maintainer note: keep the following in sync with pod#VARIABLES below
    '<PERL6>'           => $perl6,
    '<PERL6LIB>'        => $perl6lib,
    '<PERL6BIN>'        => $perl6bin,
    '<RAKUDO_DIR>'      => $rakudo_dir;
squirt( 'Makefile', $maketext );

# Job done.
.say for
    '',
    q[Makefile is ready. Ready to run 'make'.];


# The opposite of slurp
sub squirt( Str $filename, Str $text ) {
    my $handle = open( $filename, :w )
        or die $!;
    $handle.print: $text;
    $handle.close;
}

# This Configure.pm can work with the following ways of starting up:
# 1. The explicit way Parrot runs any Parrot Byte Code:
#    /my/parrot/parrot /my/rakudo/perl6.pbc Configure.p6
# 2. The Rakudo "Fake Executable" made by pbc_to_exe:
#    /my/rakudo/perl6 Configure.p6
# The rest are variations of 1. and 2. to sugar the command line:
# 3. A shell script perl6 for 1: '/my/parrot/parrot /my/rakudo/perl6.pbc $*':
#    /my/perl6 Configure.p6    # or 'perl6 Configure.p6' with search path
# 4. A shell alias for 1: perl6='/my/parrot/parrot /my/rakudo/perl6.pbc':
#    perl6 Configure.p6
# 5. A symbolic link for 2: 'sudo ln -s /my/rakudo/perl6 /bin':
#    perl6 Configure.p6

# Do you know of another way to execute Perl 6 scripts? Please tell the
# maintainers.

=begin pod

=head1 NAME
Makefile.pm - common code for Makefile builder and runner

=head1 SYNOPSIS

 perl6 Configure.p6

Where F<Configure.p6> generally has only these lines:

 # Configure.p6 - installer - see documentation in ../Configure.pm
 use v6; BEGIN { @*INC.push( '../..' ); }; use Configure; # proto dir

=head1 DESCRIPTION
A Perl module often needs a Makefile to specify how to build, test and
install it. A Makefile must make sense to the Unix C<make> utility.
Makefiles must often be adjusted slightly to alter the context in which
they will work. There are various tools to "make Makefiles" and this
F<Configure.p6> and F<Configure.pm> combination run purely in Perl 6.

Configure.p6 resides in the module top level directory. For covenience,
Configure.p6 usually contains only the lines shown in L<doc:#SYNOPSIS>
above, namely a comment and one line of code to pass execution to
F<Configure.pm>. Any custom actions to prepare the module can be called
by the default target in Makefile.in.

Configure.pm reads F<Makefile.in> from the module top level directory,
replaces certain variables marked like <THIS>, and writes the updated
text to Makefile in the same directory. Finally it runs the standard
'make' utility, which builds the first target defined in Makefile.

=head1 VARIABLES
C<Configure.p6> will cause the following tokens to be substituted when
creating the new F<Makefile>:

 <PERL6>        pathname of Perl 6 (fake)executable
 <PERL6LIB>     lib/ directory of the installed project
 <PERL6BIN>     bin/ directory of the installed project
 <RAKUDO_DIR>   whence Rakudo's Test.pm can be compiled

=head1 AUTHOR
Martin Berends (mberends on CPAN github #perl6 and @autoexec.demon.nl).

=end pod
