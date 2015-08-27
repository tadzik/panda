class Panda::Builder {
use Panda::Common;
use File::Find;
use Shell::Command;

method build($where, :$bone, :@deps) {
    indir $where, {
        if "Build.pm".IO.f {
            @*INC.push("file#$where");   # TEMPORARY !!!
            GLOBAL::<Build>:delete;
            require 'Build.pm';
            if ::('Build').isa(Panda::Builder) {
                ::('Build').new.build($where);
            }
            @*INC.pop;
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
