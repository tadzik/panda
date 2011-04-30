use v6;

module File::Copy;

BEGIN {
    warn "File::Copy is now deprecated, "
       ~ "please use Rakudo's IO.copy() instead";
}

sub cp(Str $from, Str $to) is export {
	my $f1 = open $from, :r, :bin;
	my $f2 = open $to, :w, :bin;
	$f2.write($f1.read(4096)) until $f1.eof;
	$f1.close;
	$f2.close;
}

=begin pod

=head1 NAME

File::Copy -- copy files

=head1 SYNOPSIS

	use File::Copy;

	cp 'source', 'destination';
	
=head1 DESCRIPTION

C<File::Copy> exports just one subroutine, cp taking two string
parameters: source and destination. If something comes wrong, the
internal open() or write() calls will die, C<copy()> has no special
error reporting.

=end pod

# vim: ft=perl6
