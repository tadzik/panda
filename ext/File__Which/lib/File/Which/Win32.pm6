
use v6;

unit class File::Which::Win32;

use NativeCall;

constant LIB      = 'shlwapi';

constant ASSOCF_OPEN_BYEXENAME = 0x2;
constant ASSOCSTR_EXECUTABLE   = 0x2;
constant MAX_PATH              = 260;
constant S_OK                  = 0;

#
#  HRESULT AssocQueryString(
#    _In_      ASSOCF   flags,
#    _In_      ASSOCSTR str,
#    _In_      LPCTSTR  pszAssoc,
#    _In_opt_  LPCTSTR  pszExtra,
#    _Out_opt_ LPTSTR   pszOut,
#    _Inout_   DWORD    *pcchOut
#  );
#
sub AssocQueryStringA(uint32 $flags, uint32 $str, Str $assoc, uint32 $extra,
  CArray[uint16] $path, CArray[uint32] $out) returns uint32 is native(LIB) { * };

method which(Str $exec, Bool :$all = False) {
  fail("Exec parameter should be defined") unless $exec;
  fail("This only works on Windows") unless $*DISTRO.is-win;

  my @PATHEXT = '';
  # WinNT. PATHEXT might be set on Cygwin, but not used.
  if ( %*ENV<PATHEXT>.defined ) {
    @PATHEXT = flat( %*ENV<PATHEXT>.split(';') );
  } else {
    # Win9X or other: doesn't have PATHEXT, so needs hardcoded.
    @PATHEXT.push( <.com .exe .bat> );
  }

  my @results;

  my @path = flat( $*SPEC.path );

  for  @path.map({ $*SPEC.catfile($_, $exec) }) -> $base  {
    for @PATHEXT -> $ext {
      my $file = $base ~ $ext;

      # Ignore possibly -x directories
      next if $file.IO ~~ :d;

      # Windows systems don't pass -x on
      # non-exe/bat/com files. so we check -e.
      # However, we don't want to pass -e on files
      # that aren't in PATHEXT, like README.
      if @PATHEXT[1..@PATHEXT.elems - 1].grep({ $file.match(/ $_ $ /, :i) })
         && $file.IO ~~ :e
      {
        if $all {
          @results.push( $file );
        } else {
          return $file;
        }
      }
    }
  }

  return @results.unique if $all;
  # Fallback to using win32 API to find executable location
  return self.which-win32-api($exec);
}

# This finds the executable path using the registry instead of the PATH
# environment variable
method which-win32-api(Str $exec) returns Str {
  my $path = CArray[uint8].new;
  $path[$_] = 0 for 0..MAX_PATH - 1;

  my $size = CArray[uint32].new;
  $size[0] = MAX_PATH;
  my $hresult = AssocQueryStringA(ASSOCF_OPEN_BYEXENAME, ASSOCSTR_EXECUTABLE,
    $exec, 0, $path, $size);

  # Return nothing if it fails
  return unless $hresult == S_OK;

  # Compose path from CArray using the size DWORD (uint32)
  # Ignore null marker from null-terminated string
  my $exe-path = '';
  for 0..$size[0] - 2 {
    $exe-path ~= chr($path[$_]);
  }

  # Return the executable path string
  return $exe-path;
}

=begin pod

=head1 NAME

File::Which::Win32 - Win32 which implementation

=head1 SYNOPSIS

  use File::Which::Win32;
  my $o = File::Which::Win32.new;
  say $o.which('perl6');

=head1 DESCRIPTION

Implements the which method under win32-based platforms

=head1 AUTHOR

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Ahmad M. Zawawi

This library is free software; you can redistribute it and/or modify it under
the MIT License

=end pod
