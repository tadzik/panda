class Panda::Installer {
use Panda::Common;
use Panda::Project;
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
    my $destdir;
    # $path-spec can be an absolute or relative path (which will defautl to a CompUnitRepo::Local::File),
    # or it is preceeded by 'inst#' or 'file#' which will choose the CompUnitRepo with this short-id.
    for grep(*.defined, %*ENV<DESTDIR>, %*CUSTOM_LIB<site home>) -> $path-spec {
        $destdir = CompUnitRepo.new($path-spec);
        last if $destdir.IO.w;
    }
    return $destdir;
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
        if $to.^can('install') {
            my @files;
            if 'blib'.IO ~~ :d {
                @files.push: find(dir => 'blib', type => 'file').list.grep( -> $lib {
                    next if $lib.basename.substr(0, 1) eq '.';
                    $lib
                } )
            }
            if 'bin'.IO ~~ :d {
                @files.push: find(dir => 'bin', type => 'file').list.grep( -> $bin {
                    next if $bin.basename.substr(0, 1) eq '.';
                    next if !$*DISTRO.is-win and $bin.basename ~~ /\.bat$/;
                    $bin
                } )
            }
            $to.install(:dist($bone), @files);
        }
        else {
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
        }
        1;
    }
}

}

# vim: ft=perl6
