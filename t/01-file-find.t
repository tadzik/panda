use v6;
use Test;
use File::Find;

my $res = find(:dir<t/dir1>);
my @test = $res.map({ .Str }).sort;
is @test, <t/dir1/another_dir t/dir1/another_dir/empty_file t/dir1/file.bar t/dir1/file.foo t/dir1/foodir t/dir1/foodir/not_a_dir>, 'just a dir';

# names

$res = find(:dir<t/dir1>, :name(/foo/));
@test = $res.map({ .Str }).sort;
is @test, <t/dir1/file.foo t/dir1/foodir t/dir1/foodir/not_a_dir>, 'name with regex';

$res = find(:dir<t/dir1>, :name<file.bar>);
is $res.elems, 1, 'name with a string';

$res = find(:dir<t/dir1>, :name<notexisting>);
is $res.elems, 0, 'no results';

# types

$res = find(:dir<t/dir1>, :type<dir>);
@test = $res.map({ .Str }).sort;
is @test, <t/dir1/another_dir t/dir1/foodir>, 'types: dir';

$res = find(:dir<t/dir1>, :type<dir>, :name(/foo/));
@test = $res.map({ .Str }).sort;
is @test, <t/dir1/foodir>, 'types: dir, combined with name';

$res = find(:dir<t/dir1>, :type<file>, :name(/foo/));
@test = $res.map({ .Str }).sort;
is @test, <t/dir1/file.foo t/dir1/foodir/not_a_dir>,
	'types: file, combined with name';

done;
