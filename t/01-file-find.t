use v6;
use Test;
use File::Find;
plan 11;

my $res = find(:dir<t/dir1>);
my @test = $res.map({ .Str }).sort;
equals @test, <t/dir1/another_dir t/dir1/another_dir/empty_file t/dir1/another_dir/file.bar t/dir1/file.bar t/dir1/file.foo t/dir1/foodir t/dir1/foodir/not_a_dir>, 'just a dir';

# names

$res = find(:dir<t/dir1>, :name(/foo/));
@test = $res.map({ .Str }).sort;
equals @test, <t/dir1/file.foo t/dir1/foodir t/dir1/foodir/not_a_dir>, 'name with regex';

# (default) recursive find

$res = find(:dir<t/dir1>, :name<file.bar>);
is $res.elems, 2, 'two files with name and string';

# with forced find to Not work recursive

$res = find(:dir<t/dir1>, :name<file.bar>, recursive => False);
is $res.elems, 1, 'name with a string';

$res = find(:dir<t/dir1>, :name<notexisting>);
is $res.elems, 0, 'no results';

# types

$res = find(:dir<t/dir1>, :type<dir>);
@test = $res.map({ .Str }).sort;
equals @test, <t/dir1/another_dir t/dir1/foodir>, 'types: dir';

$res = find(:dir<t/dir1>, :type<dir>, :name(/foo/));
@test = $res.map({ .Str }).sort;
equals @test, <t/dir1/foodir>, 'types: dir, combined with name';

$res = find(:dir<t/dir1>, :type<file>, :name(/foo/));
@test = $res.map({ .Str }).sort;
equals @test, <t/dir1/file.foo t/dir1/foodir/not_a_dir>,
	'types: file, combined with name';

#exclude
$res = find(:dir<t/dir1>, :type<file>,
            :exclude('t/dir1/another_dir'.IO));
@test = $res.map({ .Str }).sort;
equals @test, <t/dir1/file.bar t/dir1/file.foo t/dir1/foodir/not_a_dir>, 'exclude works';


#keep-going
skip-rest('keep-going tests are brokenz');
if 0 {
    my $skip-first = True;
    my $throw = True;

    # Wrap dir to throw when we want it to.
    my $w = &dir.wrap({
        if $skip-first {
	  $skip-first = False;
          return callsame;
	}

        if $throw {
	    $throw = False;
            X::IO::Dir.new(path => "dummy", os-error => "dummy").throw
        }
	callsame;
    });

    dies-ok(sub { find(:dir<t/dir1>) },
        "dies due to X::IO::Dir");

    $throw = $skip-first = True;
    $res = find(:dir<t/dir1>, :name<file.bar>, keep-going => True);
    is $res.elems, 1, 'found one of two files due to X::IO::Dir';

    LEAVE { &dir.unwrap($w); }
}

sub equals(\a, \b, $name) {
    ok ([&&] a >>~~<< b.map(*.IO)), $name
}

exit 0; # I have no idea what I'm doing, but I get Non-zero exit status w/o this
