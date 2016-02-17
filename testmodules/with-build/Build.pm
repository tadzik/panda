use v6;

use Panda::Common;
use Panda::Builder;
use Test;

class Build is Panda::Builder {
    method build($workdir) {
        $PANDATEST::RAN = True;
    }
}
