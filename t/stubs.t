use v6;
use Test;
use Test::Mock;
use Pies;

plan 11;

my $dep = Pies::Project.new(
    name => 'dep',
    dependencies => <nesteddep>,
);

my $nesteddep = Pies::Project.new(
    name => 'nesteddep',
    dependencies => [],
);

my $proj = Pies::Project.new(
    name => 'dummy',
    dependencies => <dep>,
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
        Bool::True
    }
}

role DummyBuilder does Pies::Builder {
    method build(Pies::Project $a) {
        Bool::True
    }
}

role DummyTester does Pies::Tester {
    method test(Pies::Project $a) {
        Bool::True
    }
}

role DummyInstaller does Pies::Installer {
    method install(Pies::Project $a) {
        Bool::True
    }
}

my $eco = DummyEco.new;
$eco.add-project($proj);
$eco.add-project($dep);
$eco.add-project($nesteddep);

class F does DummyFetcher   {};
class B does DummyBuilder   {};
class T does DummyTester    {};
class I does DummyInstaller {};
my $f = mocked(F);
my $b = mocked(B);
my $t = mocked(T);
my $i = mocked(I);

my $p = Pies.new(
    ecosystem => $eco,
    fetcher   => $f,
    builder   => $b,
    tester    => $t,
    installer => $i,
);

is $p.ecosystem.project-get-state($proj), 'absent',
                                          'state before resolving ok 1';
is $p.ecosystem.project-get-state($dep), 'absent',
                                         'state before resolving ok 2';
is $p.ecosystem.project-get-state($nesteddep), 'absent',
                                         'state before resolving ok 3';


$p.resolve($proj.name);

is $p.ecosystem.project-get-state($proj), 'installed',
                                          'state after resolving ok 1';
is $p.ecosystem.project-get-state($dep), 'installed-dep',
                                         'state after resolving ok 2';
is $p.ecosystem.project-get-state($nesteddep), 'installed-dep',
                                         'state after resolving ok 3';

# makes sure that Pies actually uses our ecosystem, not modifies its
# own, internal copy
is $eco.project-get-state($proj), 'installed',
                                  'same state in our object';

check-mock($f, *.called('fetch',   times => 3));
check-mock($b, *.called('build',   times => 3));
check-mock($t, *.called('test',    times => 3));
check-mock($i, *.called('install', times => 3));

# vim: ft=perl6
