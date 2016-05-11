class Panda::Project {
    use JSON::Fast;
    
    has $.name;
    has $.version;
    has @.dependencies;
    has %.metainfo;

    has $.build-output is rw;
    has $.build-stdout is rw;
    has $.build-stderr is rw;
    has $.build-passed is rw;
    has $.test-output is rw;
    has $.test-stdout is rw;
    has $.test-stderr is rw;
    has $.test-passed is rw;

    enum State <absent installed-dep installed>;

    method Str { $!name }

    method gist { "Panda::Project($!name)" }

    method update-from-meta-file($metafile) {
        my $mod = from-json slurp $metafile;
        $!name     = $mod<name>;
        $!version  = $mod<version>;
        %!metainfo = $mod;
        @!dependencies = (flat
                @($mod<depends> // Empty),
                @($mod<test-depends> // Empty),
                @($mod<build-depends> // Empty)
            ).unique.Array,
    }
}
