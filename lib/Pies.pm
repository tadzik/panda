class Pies::Project {
    has $.name;
    has $.version;
    has @.dependencies;
    has %.metainfo;

    subset State of Str where any(<absent installed-dep installed>);
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
    has Pies::Fetcher   $.fetcher;
    has Pies::Builder   $.builder;
    has Pies::Tester    $.tester;
    has Pies::Installer $.installer;

    method announce(Str $what, $data) { }

    method fetch-helper(Pies::Project $bone) {
        self.announce('fetching', $bone);
        $!fetcher.fetch($bone);
    }
    method build-helper(Pies::Project $bone) {
        self.announce('building', $bone);
        $!builder.build($bone);
    }
    method test-helper(Pies::Project $bone) {
        self.announce('testing', $bone);
        $!tester.test($bone);
    }
    method install-helper(Pies::Project $bone) {
        self.announce('installing', $bone);
        $!installer.install($bone);
    }
    method deps-helper(Pies::Project $bone) {
        return unless $bone.dependencies[0];
        # return a list of projects to be installed
        my @deps = $bone.dependencies.map: {
            my $littlebone = $.ecosystem.get-project($_)
               or die "{$bone.name} depends on $_, "
                      ~ "which was not found in the ecosystem";

            next unless $.ecosystem.project-get-state($littlebone)
                 eq 'absent';
            $littlebone;
        };
        self.announce('depends', $bone => @deps».name) if +@deps;
        return @deps;
    }

    method resolve-helper(Pies::Project $bone, $nodeps,
                          $notests, $isdep as Bool) {
        unless $nodeps {
            for self.deps-helper($bone) {
                next unless $.ecosystem.project-get-state($bone)
                    eq 'absent';
                self.resolve-helper($_, $nodeps, $notests, 1);
            }
        }

        self.fetch-helper($bone);
        self.build-helper($bone);
        self.test-helper($bone) unless $notests;
        self.install-helper($bone);

        $.ecosystem.project-set-state($bone, $isdep ?? 'installed-dep'
                                                    !! 'installed');
        self.announce('success', $bone);
    }

    method resolve($proj as Str, Bool :$nodeps, Bool :$notests) {
        my $bone = $.ecosystem.get-project($proj)
                   or die "Project $proj not found in the ecosystem";

        self.resolve-helper($bone, $nodeps, $notests, 0);
    }
}

# vim: ft=perl6
