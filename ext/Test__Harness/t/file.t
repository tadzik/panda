use v6;
use Test;
use Test::Harness;
plan 39;

my $h = Test::Harness::File.new;
$h.line('1..15');
is $h.tests-planned, 15, 'plan parsed correctly';
dies_ok { $h.line('1..30') }, 'can only plan once';

$h.line('ok');
diag 'testing bare ok';
is $h.tests-ran, 1;
is $h.tests-passed, 1;
is $h.tests-skipped, 0;
is $h.todos, 0;
is $h.successful, True, 'it went okay';

$h.line('not ok');
diag 'testing bare not ok';
is $h.tests-ran, 2;
is $h.tests-passed, 1;
is $h.tests-skipped, 0;
is $h.todos, 0;
is $h.successful, False, 'it went okay... NOT';

diag 'garbage input';
lives_ok {
    $h.line('# I am a comment');
    $h.line('foo baz');
    $h.line('notok');
}
is $h.tests-ran, 2;
is $h.tests-passed, 1;
is $h.tests-skipped, 0;
is $h.todos, 0;

diag 'wrong test number';
dies_ok { $h.line('ok 1') }

diag 'basic legitimate input';
$h = Test::Harness::File.new;
lives_ok {
    $h.line('ok 1');
    $h.line('not ok 2');
    $h.line('ok 3 - test description');
    $h.line('not ok 4 test description');
}
is $h.tests-ran, 4;
is $h.tests-passed, 2;
is $h.tests-skipped, 0;
is $h.todos, 0;
is $h.successful, False, 'it went okay... NOT';

diag 'todoed tests';
$h = Test::Harness::File.new;
lives_ok {
    $h.line('ok 1 # TODO');
    $h.line('ok 2 # TODO foo');
    $h.line('not ok 3 # ToDO');
    $h.line('not ok 4 # TODo foo');
}
is $h.tests-ran, 4, '4 tests ran';
is $h.tests-passed, 4, '4 tests passed';
is $h.todos, 4, '4 todoed tests';
is $h.todos-passed, 2, '2 todos passed';
is $h.successful, True, 'it went okay';

diag 'skipped tests';
$h = Test::Harness::File.new;
lives_ok {
    $h.line('ok 1 # SKIP');
    $h.line('ok 2 # SKIP foo');
    $h.line('not ok 3 # skip');
    $h.line('not ok 4 # skip foo');
}
is $h.tests-ran, 4;
is $h.tests-passed, 4;
is $h.todos, 0;
is $h.todos-passed, 0;
is $h.tests-skipped, 4;
is $h.successful, True, 'it went okay';

dies_ok { $h.line('ok foo bar #dupa') }, 'malformed TAP';

$h = Test::Harness::File.new;
lives_ok { $h.line("ok 1 - JSON string «{}» parsed") },
         'does not fail on funny characters';
