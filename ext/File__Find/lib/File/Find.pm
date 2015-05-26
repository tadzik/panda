use v6;

unit module File::Find;

sub checkrules ($elem, %opts) {
    if %opts<name>.defined {
        if %opts<name> ~~ Str {
            return False unless $elem.basename ~~ %opts<name>
        } else {
            return False unless $elem ~~ %opts<name>
        }
    }
    if %opts<type>.defined {
        given %opts<type> {
            when 'dir' {
                return False unless $elem ~~ :d
            }
            when 'file' {
                return False unless $elem ~~ :f
            }
            when 'symlink' {
                return False unless $elem ~~ :l
            }
            default {
                die "type attribute has to be dir, file or symlink";
            }
        }
    }
    return True
}

sub find (:$dir!, :$name, :$type, :$exclude = False, Bool :$recursive = True,
    Bool :$keep-going = False) is export {

    my @targets = dir($dir);
    my $list = gather while @targets {
        my $elem = @targets.shift;
        # exclude is special because it also stops traversing inside,
        # which checkrules does not
        next if $elem ~~ $exclude;
        take $elem if checkrules($elem, { :$name, :$type, :$exclude });
        if $recursive {
            if $elem.IO ~~ :d {
                @targets.push: dir($elem);
                CATCH { when X::IO::Dir {
                    $_.throw unless $keep-going;
                    next;
                }}
            }
        }
    }
    return $list;
}

=begin pod

=head1 NAME

File::Find - Get a lazy list of a directory tree

=head1 SYNOPSIS

    use File::Find;

    my @list := find(dir => 'foo');
    say @list[0..3];

    my $list = find(dir => 'foo');
    say $list[0..3];

=head1 DESCRIPTION

C<File::Find> allows you to get the contents of the given directory,
recursively, depth first.
The only exported function, C<find()>, generates a lazy
list of files in given directory. Every element of the list is an
C<IO::Path> object, described below.
C<find()> takes one (or more) named arguments. The C<dir> argument
is mandatory, and sets the directory C<find()> will traverse. 
There are also few optional arguments. If more than one is passed,
all of them must match for a file to be returned.

=head2 name

Specify a name of the file C<File::Find> is ought to look for. If you
pass a string here, C<find()> will return only the files with the given
name. When passing a regex, only the files with path matching the
pattern will be returned. Any other type of argument passed here will
just be smartmatched against the path (which is exactly what happens to
regexes passed, by the way).

=head2 type

Given a type, C<find()> will only return files being the given type.
The available types are C<file>, C<dir> or C<symlink>.

=head2 exclude

Exclude is meant to be used for skipping certain big and uninteresting
directories, like '.git'. Neither them nor any of their contents will be
returned, saving a significant amount of time.

=head2 keep-going

Parameter C<keep-going> tells C<find()> to not stop finding files
on errors such as 'Access is denied', but rather ignore the errors
and keep going.

=head1 Perl 5's File::Find

Please note, that this module is not trying to be the verbatim port of
Perl 5's File::Find module. Its interface is closer to Perl 5's
File::Find::Rule, and its features are planned to be similar one day.

=head1 CAVEATS

List assignment is eager in Perl 6, so if You assign C<find()> result
to an array, the elements will be copied and the laziness will be
spoiled. For a proper lazy list, use either binding (C<:=>) or assign
a result to a scalar value (see SYNOPSIS).

=end pod

# vim: ft=perl6
