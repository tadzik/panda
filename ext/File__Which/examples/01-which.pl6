#!/usr/bin/env perl6

use v6;
use lib 'lib';
use File::Which;

# All perl executables in PATH
say which('perl6', :all);

# First executable in PATH
say which('perl6');
