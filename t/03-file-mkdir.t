use v6;
use Test;
use File::Mkdir;

mkdir 't/dupa';
ok ('t/dupa'.IO ~~ :d), 'casual mkdir still works';
mkdir 't/dupa/foo/bar', :p;
ok ('t/dupa/foo'.IO ~~ :d), 'mkdir :p, 1/2';
ok ('t/dupa/foo/bar'.IO ~~ :d), 'mkdir :p, 1/2';
unlink 't/dupa/foo/bar';
unlink 't/dupa/foo';
unlink 't/dupa/';
done_testing;
