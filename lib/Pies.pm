subset Pies::Project::State of Str where
    'absent' | 'installed-dep' | 'installed';

class Pies::Project {
    has $.name;
    has $.version;
    has $.description;
    has @.dependencies;
    has $.url;
}

role Pies::Ecosystem {
    method add-project(Pies::Project $p) { !!! }
    method get-project($p as Str) { !!! }

    method project-set-state(Pies::Project $p,
                             Pies::Project::State $s) { !!! }
    method project-get-state(Pies::Project $p) { !!! }
}

role Pies::Fetcher {
    method fetch(Pies::Project)   { !!! }
}

role Pies::Builder {
    method build(Pies::Project)   { !!! }
}

role Pies::Tester {
    method test(Pies::Project)    { !!! }
}

role Pies::Installer {
    method install(Pies::Project) { !!! }
}

class Pies {
    has Pies::Ecosystem $.ecosystem;
    has Pies::Fetcher   $!fetcher;
    has Pies::Builder   $!builder;
    has Pies::Tester    $!tester;
    has Pies::Installer $!installer;

    method resolve-helper(Pies::Project $bone) {
        $!fetcher.fetch:     $bone;
        $!builder.build:     $bone;
        $!tester.test:       $bone;
        $!installer.install: $bone;
    }

    method resolve($proj as Str) {
        my $bone = $.ecosystem.get-project($proj);

        for $bone.dependencies -> $dep {
            my $littlebone = $.ecosystem.get-project($dep);
            unless $littlebone {
                die "Dependency $dep not found in the ecosystem";
            }
            self.resolve-helper($littlebone);
            $.ecosystem.project-set-state($littlebone, 'installed-dep');
        }

        self.resolve-helper($bone);
        $.ecosystem.project-set-state($bone, 'installed');
    }
}

# vim: ft=perl6
