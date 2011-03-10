use Pies;
use Panda::Common;
use File::Find;
use File::Mkdir;

class Panda::Installer does Pies::Installer {
    has $!srcdir;
    has $!destdir;

    method install(Pies::Project $p) {
        indir "$!srcdir/{dirname $p.name}", {
            if 'blib'.IO ~~ :d {
                for find(dir => 'blib', type => 'file').list -> $i {
                    # .substr(5) to skip 'blib/'
                    mkdir "$!destdir/{$i.dir.substr(5)}", :p;
                    run "cp $i $!destdir/{$i.Str.substr(5)}"
                        and die "cp failed";
                }
            }
            if 'bin'.IO ~~ :d {
                for find(dir => 'bin', type => 'file').list -> $bin {
                    mkdir "$!destdir/{$bin.dir}", :p;
                    run "cp $bin $!destdir/$bin"
                        and die "cp failed";
                    "$!destdir/$bin".IO.chmod(0o755);
                    run "chmod 755 $!destdir/$bin"
                        and die "chmod failed";
                }
            }
        };
    }
}

# vim: ft=perl6
