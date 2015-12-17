class Panda::Builder {
use Panda::Common;
use File::Find;
use Shell::Command;

method build($where, :$bone, :@deps) {
    indir $where, {
        if "Build.pm".IO.f {
            GLOBAL::<Build>:delete;
            require 'Build.pm';
            if ::('Build').isa(Panda::Builder) {
                ::('Build').new.build($where);
            }
        }
    };
    return True;
}

}

# vim: ft=perl6
