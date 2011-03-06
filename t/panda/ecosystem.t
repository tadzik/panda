use Test;
use Test::Mock;
use Panda::Ecosystem;
plan 12;

my $a = Panda::Ecosystem.new(
    statefile    => 't/panda/fakestate',
    projectsfile => 't/panda/fakeprojects'
);

my $b = $a.get-project('foo');
is $b.version, 1, 'get-project 1';

$b = Pies::Project.new(name => 'new', version => 5);
$a.add-project($b);
$b = $a.get-project('new');
is $b.version, 5, 'get-project 2';
$b = $a.get-project('foo');
is $b.version, 1, 'get-project 3';

is $a.project-get-state($b), 'absent', 'get-state 1';
is $a.project-get-state($a.get-project('new')), 'absent', 'get-state 2';
$a.project-set-state($b, 'installed');
is $a.project-get-state($b), 'installed', 'get-state 3';

is $b.metainfo<repo-type>, 'git', 'metainfo ok';

say $b.dependencies.perl;
is $b.dependencies[0], 'some',  'dependencies 1';
is $b.dependencies[1], 'thing', 'dependencies 2';
is $b.dependencies[2], 'else',  'dependencies 3';

skip('args to constructors not there yet in Test::Mock', 2);
try {
    check-mock($a, *.called('init-projects', times => 1));
    check-mock($a, *.called('init-states',   times => 1));
}

# vim: ft=perl6
