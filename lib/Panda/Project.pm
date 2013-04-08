class Panda::Project {
    has $.name;
    has $.version;
    has @.dependencies;
    has %.metainfo;

    enum State <absent installed-dep installed>;
}
