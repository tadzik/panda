#!/bin/sh
PWD=`pwd`
PERL6LIB=$PWD/ext:$PWD/lib perl6 bin/panda install File::Tools JSON::Tiny Test::Mock ufo
ufo
make test
make install
rm Makefile
