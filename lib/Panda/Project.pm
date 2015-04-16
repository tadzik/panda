class Panda::Project {
    has $.name;
    has $.version;
    has @.dependencies;
    has %.metainfo;

    has $.build-output is rw;
    has $.build-passed is rw;
    has $.test-output is rw;
    has $.test-passed is rw;

    enum State <absent installed-dep installed>;

    method Str { $!name }

    method gist { "Panda::Project($!name)" }
}
