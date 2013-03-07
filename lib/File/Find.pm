use v6;

module File::Find;

class File::Find::Result is Cool {
	has $.dir;
	has $.name;

	method Str {
		$.dir ~ '/' ~ $.name
	}
}

sub checkrules ($elem, %opts) {
	if %opts<name>.defined {
		given %opts<name> {
			when Regex {
				return False unless $elem ~~ %opts<name>
			}
			when Str {
				return False unless $elem.name ~~ %opts<name>
			}
			default {
				die "name attribute has to be either Regex or Str"
			}
		}
	}
	if %opts<type>.defined {
		given %opts<type> {
			when 'dir' {
				return False unless $elem.IO ~~ :d
			}
			when 'file' {
				return False unless $elem.IO ~~ :f
			}
			when 'symlink' {
				return False unless $elem.IO ~~ :l
			}
			default {
				die "type attribute has to be dir, file or symlink";
			}
		}
	}
	return True
}

sub find (:$dir!, :$name, :$type, Bool :$recursive = True) is export {
	my @targets = dir($dir).map: {
		File::Find::Result.new(dir => $dir, name => .basename);
	};
	my $list = gather while @targets {
		my $elem = @targets.shift;
		take $elem if checkrules($elem, { :$name, :$type });
		if $recursive {
			if $elem.IO ~~ :d {
				for dir($elem) -> $file {
					@targets.push(
						File::Find::Result.new(dir => $elem, name => $file.basename)
						);
				}
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
recursively. The only exported function, C<find()>, generates a lazy
list of files in given directory. Every element of the list is a
C<File::Find::Result> object, described below.
C<find()> takes one (or more) named arguments. The C<dir> argument
is mandatory, and sets the directory C<find()> will traverse. 
There are also few optional arguments. If more than one is passed,
all of them must match for a file to be returned.

=head2 name

Specify a name of the file C<File::Find> is ought to look for. If you
pass a string here, C<find()> will return only the files with the given
name. When passing a regex, only the files with path matching the
pattern will be returned.

=head2 type

Given a type, C<find()> will only return files being the given type.
The available types are C<file>, C<dir> or C<symlink>.

=head1 File::Find::Result

C<File::Find::Result> object acts like a normal string, having two
additional accessors, C<dir> and C<name>, holding the directory
the file is in and the filename respectively.

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
