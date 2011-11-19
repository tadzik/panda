use Pies;
use Panda::Common;
use File::Find;
use Shell::Command;

class Panda::Builder does Pies::Builder {
    has $.resources;

    method build-order(@list) {
        # TODO
        return @list
    }

    method build(Pies::Project $p) {
        my $workdir = $!resources.workdir($p);
        return unless "$workdir/lib".IO ~~ :d;
        indir $workdir, {
            if "Configure.pl".IO ~~ :f {
                shell 'perl6 Configure.pl' and die "Configure.pl failed";
            }

            if "Makefile".IO ~~~ :f {
                shell 'make' and die "'make' failed";
                return; # it's alredy built
            }

            # list of files to compile
            my @files = find(dir => 'lib', name => /\.pm6?$/).list;
            my @dirs = @files.map(*.dir).uniq;
            mkpath "blib/$_" for @dirs;

            my @tobuild = self.build-order(@files);
            my $p6lib = "{cwd}/blib/lib:{cwd}/lib:{%*ENV<PERL6LIB>}";
            for @tobuild -> $file {
                $file.IO.copy: "blib/{$file.dir}/{$file.name}";
                shell "env PERL6LIB=$p6lib perl6 --target=pir "
                    ~ "--output=blib/{$file.dir}/"
                    ~ "{$file.name.subst(/\.pm6?$/, '.pir')} $file"
                    and die "Failed building $file";
            }
        };
    }
}

# vim: ft=perl6
