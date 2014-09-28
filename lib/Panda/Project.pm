class Panda::Project {
    has $.name;
    has $.auth;
    has $.version;
    has @.dependencies;
    has %.metainfo;

    enum State <absent installed-dep installed>;
}
