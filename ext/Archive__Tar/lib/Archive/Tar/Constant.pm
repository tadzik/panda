use v6;

#~ BEGIN {
    #~ require Exporter;

    #~ $VERSION    = '2.00';
    #~ @ISA        = qw[Exporter];

    #~ require Time::Local if $^O eq "MacOS";
#~ }

#~ @EXPORT = Archive::Tar::Constant->_list_consts( __PACKAGE__ );
sub READ_ONLY($a) is export { $a ?? { :r, :b } !! :r }

sub EXPORT(|) {
    my %EXPORT;
    %EXPORT<FILE>           = 0;
    %EXPORT<HARDLINK>       = 1;
    %EXPORT<SYMLINK>        = 2;
    %EXPORT<CHARDEV>        = 3;
    %EXPORT<BLOCKDEV>       = 4;
    %EXPORT<DIR>            = 5;
    %EXPORT<FIFO>           = 6;
    %EXPORT<SOCKET>         = 8;
    %EXPORT<UNKNOWN>        = 9;
    %EXPORT<LONGLINK>       = 'L';
    %EXPORT<LABEL>          = 'V';

    %EXPORT<BUFFER>         = 4096;
    %EXPORT<HEAD>           = 512;
    %EXPORT<BLOCK> = my \BLOCK = 512;

    %EXPORT<COMPRESS_GZIP>  = 9;
    %EXPORT<COMPRESS_BZIP>  = 'bzip2';

    %EXPORT<&BLOCK_SIZE>   := { my $n = ($^a/BLOCK).Int; $n++ if $^a % BLOCK; $n * BLOCK };
    %EXPORT<TAR_PAD>       := -> $a? { my $x = $a || return; return "\x0" x (BLOCK - ($x % BLOCK) ) };
    %EXPORT<TAR_END>        = Buf.new(0 xx BLOCK);

    #~ %EXPORT<&READ_ONLY>    := { $^a ?? { :r, :b } !! :r };
    %EXPORT<&WRITE_ONLY>   := { $^a ?? 'wb' ~ $^a !! 'w' };
    %EXPORT<&MODE_READ>    := { so $^a ~~ /^r/ };

    # Pointless assignment to make -w shut up
    #~ my $getpwuid; $getpwuid = 'unknown' unless eval { my $f = getpwuid (0); };
    #~ my $getgrgid; $getgrgid = 'unknown' unless eval { my $f = getgrgid (0); };
    #~ %EXPORT<UNAME>          = sub { $getpwuid || scalar getpwuid( shift() ) || '' };
    #~ %EXPORT<GNAME>          = sub { $getgrgid || scalar getgrgid( shift() ) || '' };
    #~ %EXPORT<UID>            = $>;
    #~ %EXPORT<GID>            = (split ' ', $) )[0];

    #~ %EXPORT<MODE>          := do { 0o666 & (0o777 +& +^IO.umask) };
    %EXPORT<STRIP_MODE>    := { $^a +& 0o777 };
    %EXPORT<CHECK_SUM>      = "      ";

    %EXPORT<UNPACK>         = 'A100 A8 A8 A8 a12 A12 A8 A1 A100 A6 A2 A32 A32 A8 A8 A155 x12';	# cdrake - size must be a12 - not A12 - or else screws up huge file sizes (>8gb)
    %EXPORT<PACK>           = 'a100 a8 a8 a8 a12 a12 A8 a1 a100 a6 a2 a32 a32 a8 a8 a155 x12';
    %EXPORT<NAME_LENGTH>    = 100;
    %EXPORT<PREFIX_LENGTH>  = 155;

    #~ %EXPORT<TIME_OFFSET>    = ($*DISTRO.name eq "MacOS") ? Time::Local::timelocal(0,0,0,1,0,70) : 0;
    %EXPORT<TIME_OFFSET>    = 0;
    %EXPORT<MAGIC>          = "ustar";
    %EXPORT<TAR_VERSION>    = "00";
    %EXPORT<LONGLINK_NAME>  = '././@LongLink';
    %EXPORT<PAX_HEADER>     = 'pax_global_header';

    %EXPORT<ZLIB>          := -> { ::('Compress::Zlib') !~~ Failure };
                            ### allow BZIP to be turned off using ENV: DEBUG only
    %EXPORT<BZIP>           = do { my $!; !%*ENV<PERL5_AT_NO_BZIP> and
                                try { require IO::Uncompress::Bunzip2; require IO::Compress::Bzip2; };
                                %*ENV<PERL5_AT_NO_BZIP> || +not so $!
                            };

    #~ %EXPORT<GZIP_MAGIC_NUM> = anon regex { ^ [ "\o37\o213" | "\o37\o235" ] };
    %EXPORT<GZIP_MAGIC_NUM> = [0o37, 0o213], [0o37, 0o235];
    %EXPORT<BZIP_MAGIC_NUM> = anon regex { ^ BZh\d };

    #~ %EXPORT<CAN_CHOWN>      = sub { ($> == 0 and $*DISTRO.name ne "MacOS" and $*DISTRO.name ne "MSWin32") };
    %EXPORT<CAN_READLINK>   = ($*DISTRO.name ne 'MSWin32' and $*DISTRO.name ~~ m/ :i RISC <[ _]>? OS / and $*DISTRO.name ne 'VMS');
    %EXPORT<ON_UNIX>        = ($*DISTRO.name ne 'MSWin32' and $*DISTRO.name ne 'MacOS' and $*DISTRO.name ne 'VMS');
    %EXPORT<ON_VMS>         = $*DISTRO.name eq 'VMS';
    %EXPORT;
}

class Archive::Tar::Constant;
sub _list_consts {
    #~ my $class = shift;
    #~ my $pkg   = shift;
    #~ return unless defined $pkg; # some joker might use '0' as a pkg...

    #~ my @rv;
    #~ {   no strict 'refs';
        #~ my $stash = $pkg . '::';

        #~ for my $name (sort keys %$stash ) {

            ### is it a subentry?
            #~ my $sub = $pkg->can( $name );
            #~ next unless defined $sub;

            #~ next unless defined prototype($sub) and
                     #~ not length prototype($sub);

            #~ push @rv, $name;
        #~ }
    #~ }

    #~ return sort @rv;
}
