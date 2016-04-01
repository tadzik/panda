
use v6;

use File::Which::Unix;
use File::Which::MacOSX;
use File::Which::Win32;

unit module File::Which;

# Current which platform-specific implementation
my $platform;

sub which(Str $exec, Bool :$all = False) is export {

  unless $platform.defined {
    if $*DISTRO.is-win {
      $platform = File::Which::Win32.new;
    } elsif $*DISTRO.name eq 'macosx' {
      $platform = File::Which::MacOSX.new;
    } else {
      $platform = File::Which::Unix.new;
    }
  }

  return $platform.which($exec, :$all);
}

sub whence(Str $exec, Bool :$all = False) is export(:all, :whence) {
  return which($exec, :$all);
}

=begin pod

=head1 NAME

File::Which - Cross platform Perl 6 executable path finder (aka which on UNIX)

=head1 SYNOPSIS

  use File::Which :whence;

  # All perl executables in PATH
  say which('perl6', :all);

  # First executable in PATH
  say which('perl6');

  # Same as which('perl6')
  say whence('perl6');

=head1 DESCRIPTION

This is a Perl 6 Object-oriented port of L<File::Which (CPAN)|https://metacpan.org/pod/File::Which>.

File::Which finds the full or relative paths to an executable program on the
system. This is normally the function of which utility which is typically
implemented as either a program or a built in shell command. On some unfortunate
platforms, such as Microsoft Windows it is not provided as part of the core
operating system.

This module provides a consistent API to this functionality regardless of the
underlying platform.

=head1 AUTHOR

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Ahmad M. Zawawi

This library is free software; you can redistribute it and/or modify it under
the MIT License

=end pod
