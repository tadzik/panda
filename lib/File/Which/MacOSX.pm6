
use v6;

unit class File::Which::MacOSX;

method which(Str $exec, Bool :$all = False) {
  fail("Exec parameter should be defined") unless $exec;
  fail("This only works on Mac OS X") unless $*DISTRO.name eq 'macosx';

  my @results;

  # check for aliases first
  my @aliases = %*ENV<Aliases>:exists ?? %*ENV<Aliases>.split( ',' ) !! ();
  for @aliases -> $alias {
    # This has not been tested!!
    # PPT which says MPW-Perl cannot resolve `Alias $alias`,
    # let's just hope it's fixed
    if $alias.lc eq $exec.lc {
      chomp(my $file = qx<Alias $alias>);
      last unless $file;  # if it failed, just go on the normal way
      return $file unless $all;
      @results.push( $file );
      last;
    }
  }

  my @path = flat( $*SPEC.path );

  for  @path.map({ $*SPEC.catfile($_, $exec) }) -> $file  {

    # Ignore possibly -x directories
    next if $file.IO ~~ :d;

    if
      # Executable, normal case
      $file.IO ~~ :x
      # MacOS doesn't mark as executable so we check -e
      || $file.IO ~~ :e
    {
      if $all {
        @results.push( $file );
      } else {
        return $file;
      }
    }
  }

  return @results.unique if $all;
  return;
}

=begin pod

=head1 NAME

File::Which::MacOSX - MacOSX which implementation

=head1 SYNOPSIS

  use File::Which::MacOSX;
  my $o = File::Which::MacOSX.new;
  say $o.which('perl6');

=head1 DESCRIPTION

Implements the which method under the Mac OS X platform.

=head1 AUTHOR

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Ahmad M. Zawawi

This library is free software; you can redistribute it and/or modify it under
the MIT License

=end pod