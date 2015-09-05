# NAME

File::Find - Get a lazy list of a directory tree

## SYNOPSIS

    use File::Find;

    # recursively (and eagerly) find all files from the 'foo' directory
    my @list := find(dir => 'foo');
    say @list[0..3];

    # the same as above, but lazily return the results
    my $list = find(dir => 'foo');
    say $list[0..3];

    # eagerly find all Perl-related files from the current directory
    my @perl-files := find(dir => '.', name => /.p [l||m] $/);

    # lazily find all directories within the 'rakudo' directory
    my $rakudo-dirs = find(dir => 'rakudo', type => 'dir');

    # lazily find all symlinks a normal user can access under `/etc`
    my $etc-symlinks = find(dir => '/etc/', type => 'symlink', keep-going => True);

## DESCRIPTION

`File::Find` allows you to get the contents of the given directory,
recursively, depth first.

The only exported function, `find()`, generates a lazy
list of files in given directory. Every element of the list is an
`IO::Path` object, described below.

`find()` takes one (or more) named arguments. The `dir` argument
is mandatory, and sets the directory `find()` will traverse.

There are also a few optional arguments. If more than one is passed,
all of them must match for a file to be returned.

**name**

Specify a name of the file `File::Find` is ought to look for. If you
pass a string here, `find()` will return only the files with the given
name. When passing a regex, only the files with path matching the
pattern will be returned. Any other type of argument passed here will
just be smartmatched against the path (which is exactly what happens to
regexes passed, by the way).

**type**

Given a type, `find()` will only return files being the given type.
The available types are `file`, `dir` or `symlink.

**keep-going**

Parameter `keep-going` tells `find()` to not stop finding files
on errors such as 'Access is denied', but rather ignore the errors
and keep going.

**Perl 5's File::Find**

Please note, that this module is not trying to be the verbatim port of
Perl 5's File::Find module. Its interface is closer to Perl 5's
File::Find::Rule, and its features are planned to be similar one day.

## CAVEATS

List assignment is eager in Perl 6, so if you assign `find()` result
to an array, the elements will be copied and the laziness will be
spoiled. For a proper lazy list, use either binding (`:=`) or assign
a result to a scalar value (see SYNOPSIS).
