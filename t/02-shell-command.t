use v6;
use Test;
use Shell::Command;
plan 3;

mkpath 't/dupa/foo/bar';
ok ('t/dupa/foo'.IO ~~ :d), 'mkpath, 1/2';
ok ('t/dupa/foo/bar'.IO ~~ :d), 'mkpath, 1/2';
rmdir 't/dupa/foo/bar';
rmdir 't/dupa/foo';
rmdir 't/dupa/';

mkpath 't/a/b/c';
rm_rf('t/a');
ok !('t/a/b/c'.IO.d), 'rm_rf';
