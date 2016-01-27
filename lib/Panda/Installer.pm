class Panda::Installer {
use Panda::Common;
use Panda::Project;
use File::Find;
use Shell::Command;

has $.prefix = self.default-prefix();

method sort-lib-contents(@lib) {
    my @generated = @lib.grep({ $_ ~~  / \. <{compsuffix}> $/});
    my @rest = @lib.grep({ $_ !~~ / \. <{compsuffix}> $/});
    return flat @rest, @generated;
}

# default install location
method default-prefix {
    my @custom-lib = <site home>.map({CompUnit::RepositoryRegistry.repository-for-name($_)}).grep(*.defined);
    for @custom-lib.grep(*.can-install) -> $repo {
        return $repo;
    }
    my $ret = $*REPO.repo-chain.grep(CompUnit::Repository::Installable).first(*.can-install);
    return $ret if $ret;
    fail "Could not find a repository to install to";
}

sub copy($src, $dest) {
    note "Copying $src to $dest";
    unless $*DISTRO.is-win {
        $dest.IO.unlink;
    }
    $src.copy($dest);
}

method install($from, $to? is copy, Panda::Project :$bone, Bool :$force) {
    unless $to {
        $to = $.prefix;
    }
    $to = $to.IO.absolute if $to ~~ IO::Path; # we're about to change cwd
    if $to !~~ CompUnit::Repository and CompUnit::RepositoryRegistry.repository-for-spec($to, :next-repo($*REPO)) -> $cur {
        $to = $cur;
    }
    indir $from, {
        # check if $.prefix is under control of a CompUnit::Repository
        if $to.can('install') {
            fail "'provides' key mandatory in META information" unless $bone.metainfo<provides>:exists;
            my %sources = $bone.metainfo<provides>.map({ $_.key => ~$_.value.IO });
            my %scripts;
            if 'bin'.IO ~~ :d {
                for find(dir => 'bin', type => 'file').list -> $bin {
                    my $basename = $bin.basename;
                    next if $basename.substr(0, 1) eq '.';
                    next if !$*DISTRO.is-win and $basename ~~ /\.bat$/;
                    %scripts{$basename} = ~$bin.IO;
                }
            }
            my %resources = ($bone.metainfo<resources> // []).map({
                $_ => $_ ~~ m/^libraries\/(.*)/
                    ?? ~"resources/libraries".IO.child($*VM.platform-library-name($0.Str.IO))
                    !! ~"resources/$_".IO
            });
            $to.install(
                Distribution.new(|$bone.metainfo),
                %sources,
                %scripts,
                %resources,
                :$force,
            );
        }
        else {
            if 'lib'.IO ~~ :d {
                my @lib = find(dir => 'lib', type => 'file').list;
                for self.sort-lib-contents(@lib) -> $i {
                    next if $i.basename.substr(0, 1) eq '.';
                    mkpath "$to/{$i.dirname}";
                    copy($i, "$to/{$i}");
                }
            }
            if 'bin'.IO ~~ :d {
                for find(dir => 'bin', type => 'file').list -> $bin {
                    next if $bin.basename.substr(0, 1) eq '.';
                    next if !$*DISTRO.is-win and $bin.basename ~~ /\.bat$/;
                    mkpath "$to/{$bin.dirname}";
                    copy($bin, "$to/$bin");
                    "$to/$bin".IO.chmod(0o755) unless $*DISTRO.is-win;

                    # TODO remove this once CompUnit installation actually works
                    "$to/$bin.bat".IO.spurt(q:to[SCRIPT]
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl6 "%~dpn0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl6 "%~dpn0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
__END__
:endofperl
SCRIPT
                    );
                }
            }
        }
        1;
    }
}

}

# vim: ft=perl6
