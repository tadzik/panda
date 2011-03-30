use Pies;
use Panda::Common;
use File::Find;
use File::Mkdir;

class Panda::Installer does Pies::Installer {
    has $!resources;
    has $!destdir;

    method install(Pies::Project $p) {
        indir $!resources.workdir($p), {
            if 'Makefile'.IO ~~ :f {
                run 'make install'
                    and die "'make install' failed for {$p.name}";
                return;
            }
            if 'blib'.IO ~~ :d {
                for find(dir => 'blib', type => 'file').list -> $i {
                    # .substr(5) to skip 'blib/'
                    mkdir "$!destdir/{$i.dir.substr(5)}", :p;
                    $i.IO.copy("$!destdir/{$i.Str.substr(5)}");
                }
            }
            if 'bin'.IO ~~ :d {
                for find(dir => 'bin', type => 'file').list -> $bin {
                    mkdir "$!destdir/{$bin.dir}", :p;
                    $bin.IO.copy("$!destdir/$bin");
                    "$!destdir/$bin".IO.chmod(0o755);
                }
            }
        };
    }
}

# vim: ft=perl6
