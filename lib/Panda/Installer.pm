class Panda::Installer;
use Panda::Common;
use Panda::Project;
use File::Find;
use Shell::Command;

has $.destdir = self.destdir();

method sort-lib-contents(@lib) {
    my @generated = @lib.grep({ $_ ~~  / \. <{compsuffix}> $/});
    my @rest = @lib.grep({ $_ !~~ / \. <{compsuffix}> $/});
    return @rest, @generated;
}

# default install location
method destdir {
    my $ret = %*ENV<DESTDIR>;
    if defined($ret) && $*OS ne 'MSWin32' && $ret !~~ /^ '/' / {
        $ret = "{cwd}/$ret" ;
    }
    for grep(*.defined, $ret, %*CUSTOM_LIB<site home>) -> $prefix {
        $ret = $prefix;
        last if $ret.path.w;
    }
    return $ret;
}

sub copy($src, $dest) {
    note "Copying $src to $dest";
    $src.copy($dest);
}

method install($from, $to? is copy, Panda::Project :$bone) {
    unless $to {
        $to = $.destdir
    }
    indir $from, {
        # check if $.destdir is under control of a CompUnitRepo
        my @files;
        for <blib bin> {
            @files := (@files, find(dir => $_, type => 'file').list).flat if .IO.d
        }
        if $to.can('install') {
            $to.install(:dist($bone), @files);
        }
        else {
            if 'blib'.IO ~~ :d {
                my @lib = find(dir => 'blib', type => 'file').list;
                for self.sort-lib-contents(@lib) -> $i {
                    next if $i.basename.substr(0, 1) eq '.';
                    # .substr(5) to skip 'blib/'
                    mkpath "$to/{$i.directory.substr(5)}";
                    copy($i, "$to/{$i.substr(5)}");
                }
            }
            if 'bin'.IO ~~ :d {
                for find(dir => 'bin', type => 'file').list -> $bin {
                    next if $bin.basename.substr(0, 1) eq '.';
                    next if $*OS ne 'MSWin32' and $bin.basename ~~ /\.bat$/;
                    mkpath "$to/{$bin.directory}";
                    copy($bin, "$to/$bin");
                    "$to/$bin".IO.chmod(0o755) unless $*OS eq 'MSWin32';
                }
            }
        }
        1;
    }
}

# vim: ft=perl6
