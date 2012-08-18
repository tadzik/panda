module Shell::Command;
use File::Find;

sub cat(*@files) is export {
    for @files -> $f {
        given open($f) {
            for .lines -> $line {
                say $line;
            }
            .close
        }
    }
}

sub eqtime($source, $dest) is export {
    ???
}

sub rm_f(*@files) is export {
    for @files -> $f {
        unlink $f if $f.IO.e;
    }
}

sub rm_rf(*@files) is export {
    for @files -> $path {
        for find(dir => $path).map({ .Str }).reverse -> $f {
            $f.IO.d ?? rmdir($f) !! unlink($f);
        }
        rmdir $path;
    }
}

sub touch(*@files) is export {
    ???
}

sub mv(*@args) is export {
    ???
}

sub cp(*@args) is export {
    ???
}

sub mkpath(*@paths) is export {
    for @paths -> $name {
        for [\~] $name.split('/').map({"$_/"}) {
            mkdir($_) unless .IO.d
        }
    }
}

sub test_f($file) is export {
    ???
}

sub test_d($file) is export {
    ???
}

sub dos2unix($file) is export {
    ???
}

# vim: ft=perl6
