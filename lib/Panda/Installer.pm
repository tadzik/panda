class Panda::Installer;
use Panda::Common;
use File::Find;
use Shell::Command;

has $.destdir = self.default-destdir();

method sort-lib-contents(@lib) {
    my @generated = @lib.grep({ $_ ~~  / \. <{compsuffix}> $/});
    my @rest = @lib.grep({ $_ !~~ / \. <{compsuffix}> $/});
    return @rest, @generated;
}

# default install location
method default-destdir {
    my $ret = %*ENV<DESTDIR>;
    if defined($ret) && !$*DISTRO.is-win && $ret !~~ /^ '/' / {
        $ret = "{cwd}/$ret" ;
    }
    for grep(*.defined, $ret, %*CUSTOM_LIB<site home>) -> $prefix {
        $ret = $prefix;
        last if $ret.IO.w;
    }
    return $ret;
}

sub copy($src, $dest) {
    note "Copying $src to $dest";
    $src.copy($dest);
}

method install($from, $to? is copy) {
    unless $to {
        $to = $.destdir
    }
    indir $from, {
        if 'blib'.IO ~~ :d {
            my @lib = find(dir => 'blib', type => 'file').list;
            for self.sort-lib-contents(@lib) -> $i {
                next if $i.basename.substr(0, 1) eq '.';
                # .substr(5) to skip 'blib/'
                mkpath "$to/{$i.dirname.substr(5)}";
                copy($i, "$to/{$i.substr(5)}");
            }
        }
        if 'bin'.IO ~~ :d {
            for find(dir => 'bin', type => 'file').list -> $bin {
                next if $bin.basename.substr(0, 1) eq '.';
                next if !$*DISTRO.is-win and $bin.basename ~~ /\.bat$/;
                mkpath "$to/{$bin.dirname}";
                copy($bin, "$to/$bin");
                "$to/$bin".IO.chmod(0o755) unless $*DISTRO.is-win;
            }
        }
        1;
    };
}

# vim: ft=perl6
