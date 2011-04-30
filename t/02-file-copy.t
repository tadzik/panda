use v6;
use Test;
use File::Copy;

cp 't/test.file', 't/another.file';
is slurp('t/test.file'),
   slurp('t/another.file'),
   "copied file is identical";
unlink 't/another.file';
done;
