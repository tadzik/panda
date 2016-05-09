class Panda::Builder {
use Panda::Common;
use File::Find;
use Shell::Command;

method build($where, :$bone, :@deps) {
    indir $where, {
        if "Build.pm".IO.f {
            GLOBAL::<Build>:delete;
            require "$where/Build.pm";
            ::('Build').new.build($where);
        }
    };
    return True;
}

}

# vim: ft=perl6
