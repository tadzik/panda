use v6;
use Test;

use lib 'lib';
use Archive::Tar;

plan 1;

my $tar = Archive::Tar.new( 't/src/long/bar.tar' );
ok $tar ~~ Archive::Tar, 'Object created';
