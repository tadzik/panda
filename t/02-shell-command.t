use v6;
use Test;
use Shell::Command;
plan 2;

mkpath 't/dupa/foo/bar';
ok ('t/dupa/foo'.IO ~~ :d), 'mkpath, 1/2';
ok ('t/dupa/foo/bar'.IO ~~ :d), 'mkpath, 1/2';
unlink 't/dupa/foo/bar';
unlink 't/dupa/foo';
unlink 't/dupa/';
