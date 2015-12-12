class Panda::Builder {
use Panda::Common;
use File::Find;
use Shell::Command;

method build($where, :$bone, :@deps) {
    indir $where, {
        if "Build.pm".IO.f {
            PROCESS::<$REPO> := CompUnit::RepositoryRegistry.repository-for-spec(
                "file#$where",
                :next-repo($*REPO)
            ); # TEMPORARY !!!
            GLOBAL::<Build>:delete;
            require 'Build.pm';
            if ::('Build').isa(Panda::Builder) {
                ::('Build').new.build($where);
            }
            PROCESS::<$REPO> := $*REPO.next-repo;
        }

        my @files;
        if 'lib'.IO.d {
            @files = find(dir => 'lib', type => 'file').map({
                my $io = .IO;
                $io if $io.basename.substr(0, 1) ne '.';
            });
        }
        my @dirs = @files.map(*.dirname).unique;
        mkpath "blib/$_" for @dirs;
        for @files -> $file {
            $file.copy: "blib/$file";
        }
    };
    return True;
}

}

# vim: ft=perl6
