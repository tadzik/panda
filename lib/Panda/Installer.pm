use Pies;
use Panda::Common;
use File::Find;
use File::Mkdir;

class Panda::Installer does Pies::Installer {
    has $!srcdir;
    has $!destdir;

    method install(Pies::Project $p) {
        indir "$!srcdir/{dirname $p.name}", {
            for find(dir => 'blib', type => 'file').list -> $i {
                # .substr(5) to skip 'blib/'
                mkdir "$!destdir/{$i.dir.substr(5)}", :p;
                $i.IO.copy("$!destdir/{$i.Str.substr(5)}");
            }
            for find(dir => 'bin', type => 'file').list -> $bin {
                mkdir "$!destdir/{$bin.dir}", :p;
                $bin.IO.copy("$!destdir/$bin");
            }
        };
    }
}

# vim: ft=perl6
