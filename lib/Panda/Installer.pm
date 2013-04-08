class Panda::Installer;
use Panda::Common;
use File::Find;
use Shell::Command;

method sort-lib-contents(@lib) {
    my @pirs = @lib.grep({ $_ ~~  /\.pir$/});
    my @rest = @lib.grep({ $_ !~~ /\.pir$/});
    return @rest, @pirs;
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
    $src.IO.copy($dest);
}

method install($from, $to? is copy) {
    $to //= self.destdir();
    indir $from, {
        if 'blib'.IO ~~ :d {
            my @lib = find(dir => 'blib', type => 'file').list;
            for self.sort-lib-contents(@lib) -> $i {
                next if $i.name.substr(0, 1) eq '.';
                # .substr(5) to skip 'blib/'
                mkpath "$to/{$i.dir.substr(5)}";
                copy($i, "$to/{$i.Str.substr(5)}");
            }
        }
        if 'bin'.IO ~~ :d {
            for find(dir => 'bin', type => 'file').list -> $bin {
                next if $bin.name.substr(0, 1) eq '.';
                mkpath "$to/{$bin.dir}";
                copy($bin, "$to/$bin");
                "$to/$bin".IO.chmod(0o755) unless $*OS eq 'MSWin32';
            }
        }
        1;
    };
}

# vim: ft=perl6
