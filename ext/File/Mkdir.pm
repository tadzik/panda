use v6;

module File::Mkdir;

multi sub mkdir(Str $name, $mode = 0o777, :$p!) is export {
    for [\~] $name.split('/').map({"$_/"}) {
        mkdir($_) unless .IO.d
    }
}

=begin pod

=head1 NAME

File::Mkdir -- provides recursive mkdir

=head1 SYNOPSIS

	use File::Mkdir;

	# special mkdir exported in File::Mkdir
	mkdir '/some/directory/tree', :p;
	# just a casual, built-in mkdir
	mkdir 'directory';
	
=head1 DESCRIPTION

C<File::Mkdir> provides an mkdir variant, which, when provided the :p
parameter, will create the directory tree recursively. For example,
calling C<mkdir 'foo/bar', :p> will create the foo directory (unless
it alredy exists), then the foo/bar directory (unless it exists).
The standard Perl 6 C<mkdir> is still available, and will be called
when the :p parameter is not passed.

=end pod

# vim: ft=perl6
