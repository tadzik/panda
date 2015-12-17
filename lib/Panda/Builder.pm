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
    };
    return True;
}

}

# vim: ft=perl6
