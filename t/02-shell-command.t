use v6;
use Test;
use Shell::Command;
plan 12;

mkpath 't/dupa/foo/bar';
ok ('t/dupa/foo'.IO ~~ :d), 'mkpath, 1/2';
ok ('t/dupa/foo/bar'.IO ~~ :d), 'mkpath, 1/2';
rmdir 't/dupa/foo/bar';
rmdir 't/dupa/foo';
rmdir 't/dupa/';

mkpath 't/a/b/c';
rm_rf('t/a');
ok !('t/a'.IO.d), 'rm_rf';

cp 't/dir1', 't/dir2', :r;
ok 't/dir2'.IO.d, 'recursive cp';
ok 't/dir2/file.bar'.IO.f, 'recursive cp';
ok 't/dir2/another_dir'.IO.d, 'recursive cp';
ok 't/dir2/another_dir/empty_file'.IO.f, 'recursive cp';
ok 't/dir2/file.foo'.IO.f, 'recursive cp';
ok 't/dir2/foodir/not_a_dir'.IO.f, 'recursive cp';

rm_f 't/dir2/file.foo';
ok ! 't/dir2/file.foo'.IO.f, 'rm_f';

rm_rf 't/dir2/foodir/not_a_dir';
ok ! 't/dir2/foodir/not_a_dir'.IO.f, 'rm_rf';

rm_rf 't/dir2';
ok !'t/dir2'.IO.d, 'rm_rf';
