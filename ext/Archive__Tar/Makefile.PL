use ExtUtils::MakeMaker;
use strict;
use Getopt::Std;
use Config;
my $opt = {};
getopts( 'nd', $opt );

unless( $] >= 5.005_03 ) {
    die qq[Archive::Tar requires perl version 5.005_03 or higher to run\n];
}

if( !eval { require IO::Compress::Bzip2; 1 } and !$opt->{n} ) {
    warn    qq[You do not have IO::Compress::Bzip2 installed. This means you can ].
            qq[not read or write bzip2 compressed archives!\n] .
            qq[Note: you can disable this warning (and the prerequisite) ].
            qq[by invoking Makefile.PL with '-n'\n];
}

if( !$opt->{d} and not eval { require Text::Diff; 1 } ) {
    print   qq[\nArchive::Tar comes with a utility called 'ptardiff' which ].
            qq[lets you run diffs against tar archives.\n\nHowever, this ].
            qq[utility requires you to have Text::Diff installed.\n\n].
            qq[To add Text::Diff as a prerequisite, please supply the ].
            qq['-d' option when invoking this Makefile.PL.\n\n];
}

my $prereqs = {
    'Test::More'                    => 0,
    'File::Spec'                    => 0.82,
    'Test::Harness'                 => 2.26,    # bug in older versions
    'IO::Zlib'                      => 1.01,
    # All these should be the same version, or breakage may occurr. See:
    # http://www.nntp.perl.org/group/perl.cpan.testers/2008/08/msg2083310.html
    # Requires at least 2.015, to address: #43609: Memory problem with A::T.
    # Turns out 2.012 was leaking memory.
    'IO::Compress::Base'            => 2.015,   # base class
    'Compress::Zlib'                => 2.015,   # zlib
    'IO::Compress::Gzip'            => 2.015,   # c::z needs this
    'IO::Compress::Bzip2'           => 2.015,   # bzip2 support
};


unless ($Config{useperlio}) {
    $prereqs->{'IO::String'} = 0;       # for better 'return stringified archive'
}

### ok, you didn't want IO::Zlib ###
delete $prereqs->{'IO::Compress::Bzip2'} if $opt->{n};

### so you want text::diff ###
$prereqs->{'Text::Diff'} = 0 if $opt->{d};


WriteMakefile1(
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.00503',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/jib/archive-tar-new',
        },
    },
    #BUILD_REQUIRES => {
    #},

    NAME            => 'Archive::Tar',
    VERSION_FROM    => 'lib/Archive/Tar.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    #EXE_FILES       => ['bin/ptar', 'bin/ptardiff'],
    EXE_FILES       => [ _scripts() ],
    PREREQ_PM       => $prereqs,
    INSTALLDIRS     => ( $] >= 5.009003 && $] < 5.012 ? 'perl' : 'site' ),
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
    ABSTRACT        => 'Manipulates TAR archives',
);

sub _scripts {
  my @scripts = glob('bin/*');
  if ( $] >= 5.009003 ) {
    require Config;
    my $version = sprintf("%vd",$^V);
    if ( $Config::Config{versiononly} and
         $Config::Config{startperl} =~ /\Q$version\E$/ ) {
         require File::Copy;
         File::Copy::copy( $_, "$_$version" ) for @scripts;
         @scripts = glob("bin/*$version");
    }
    if ( $] >= 5.012 && $Config::Config{installscript} ne $Config::Config{installsitescript} ) {
      my $script = $Config::Config{installscript};
      my $site   = $Config::Config{installsitescript};
      warn <<"WARNING";
###############################################################
##
##    Hi! Your script and sitescript locations are different
##
##    As your perl is v5.12.0 or greater the script included
##    in this distribution will be installed into sitescript
##
##    You might want to check that the following location is
##    in your PATH environment variable:
##
##    '$site'
##
##    Many thanks.
##
###############################################################

WARNING
      sleep 10;
    }
  }
  return @scripts;
}

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);
}
