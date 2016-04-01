
use v6;

unit class File::Which::Unix;

method which(Str $exec, Bool :$all = False) {
  fail("Exec parameter should be defined") unless $exec;

  my @results;

  return $exec if $exec ~~ /\// && $exec.IO ~~ :f && $exec.IO ~~ :x;

  my @path = flat( $*SPEC.path );

  my @PATHEXT = '';
  for @path.map({ $*SPEC.catfile($_, $exec) }) -> $file  {

    # Ignore possibly -x directories
    next if $file.IO ~~ :d;

    # Executable, normal case
    if $file.IO ~~ :x {
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

File::Which::Unix - Linux/Unix which implementation

=head1 SYNOPSIS

  use File::Which::Unix;
  my $o = File::Which::Unix.new;
  say $o.which('perl6');

=head1 DESCRIPTION

Implements the which method under UNIX-based platforms

=head1 AUTHOR

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Ahmad M. Zawawi

This library is free software; you can redistribute it and/or modify it under
the MIT License

=end pod