use v6;
use Test;
use Pies;

plan 7;

my $proj = Pies::Project.new(
    name => 'dummy',
    dependencies => []
);

role DummyEco does Pies::Ecosystem {
    has %.projects;
    has %.states;

    method add-project(Pies::Project $p) {
        %.projects{$p.name} = $p;
        %.states{$p.name}   = 'absent';
    }

    method get-project($p as Str) {
        return %.projects{$p};
    }

    method project-set-state(Pies::Project $p, Pies::Project::State $s) {
        %.states{$p.name} = $s;
    }
    method project-get-state(Pies::Project $p) {
        return %.states{$p.name};
    }
}

role DummyFetcher does Pies::Fetcher {
    method fetch(Pies::Project $a) {
        ok 1, "{$a.name} fetched";
    }
}

role DummyBuilder does Pies::Builder {
    method build(Pies::Project $a) {
        ok 1, "{$a.name} built";
    }
}

role DummyTester does Pies::Tester {
    method test(Pies::Project $a) {
        ok 1, "{$a.name} tested";
    }
}

role DummyInstaller does Pies::Installer {
    method install(Pies::Project $a) {
        ok 1, "{$a.name} installed";
    }
}

my $eco = DummyEco.new;
$eco.add-project($proj);

my $p = Pies.new(
    ecosystem => $eco,
    fetcher   => DummyFetcher.new,
    builder   => DummyBuilder.new,
    tester    => DummyTester.new,
    installer => DummyInstaller.new,
);

is $p.ecosystem.project-get-state($proj), 'absent',
                                          'state before resolving ok';

$p.resolve($proj.name);

is $p.ecosystem.project-get-state($proj), 'installed',
                                          'state after resolving ok';

# makes sure that Pies actually uses our ecosystem, not modifies its
# own, internal copy
is $eco.project-get-state($proj), 'installed',
                                  'same state in our object';

# vim: ft=perl6
