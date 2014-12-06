class Panda::Project {
    has $.name;
    has $.auth;
    has $.version;
    has @.dependencies;
    has %.metainfo;

    has $.build-output is rw;
    has $.build-passed is rw;
    has $.test-output is rw;
    has $.test-passed is rw;

    enum State <absent installed-dep installed>;
}
