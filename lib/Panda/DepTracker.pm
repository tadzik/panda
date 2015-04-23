use nqp;

my class DepTracker is CompUnitRepo {
    method load_module($module_name, %opts, *@GLOBALish is rw, Any :$line, Any :$file, :%chosen) {
        my $r := CompUnitRepo.load_module($module_name, %opts, @GLOBALish, :$line, :$file, :%chosen);

        # get our hands on the candidate that was loaded right before.
        my $candi = CompUnitRepo.candidates($module_name, :auth(%opts<auth>), :ver(%opts<ver>))[0];
        if $candi {
            my $file = $candi<provides>{$module_name}<pm><file>;
            if %*ENV<PANDA_PROTRACKER_FILE> && nqp::existskey($r, 'GLOBALish') {
                %*ENV<PANDA_PROTRACKER_FILE>.IO.spurt:
                    { :$module_name, :$file, :symbols( symbols(nqp::atkey($r, 'GLOBALish')) ) }.perl ~ ",\n", :append;
            }
            if %*ENV<PANDA_DEPTRACKER_FILE> {
                %*ENV<PANDA_DEPTRACKER_FILE>.IO.spurt: { :$module_name, :$file, :%opts }.perl ~ ",\n", :append;
            }
        }

        $r
    }
}

nqp::bindhllsym('perl6', 'ModuleLoader', DepTracker);

sub stash_hash($pkg) {
    my $hash := $pkg.WHO;
    unless nqp::ishash($hash) {
        $hash := $hash.FLATTENABLE_HASH();
    }
    $hash
}

my $stub_how := 'Perl6::Metamodel::PackageHOW';
sub symbols($source, $key is copy = '') {
    my $symbols = [];
    $key ~= '::' if $key;

    for stash_hash($source) {
        my $meta_obj := $_.value.HOW;
        my $is_stub  := $meta_obj.HOW.name($meta_obj) eq $stub_how;

        if $is_stub {
            for symbols($_.value, $key ~ $_.key) -> $sym {
                $symbols.push: $sym.flat
            }
        }
        else {
            $symbols.push: $key ~ $_.key
        }
    }
    $symbols
}
