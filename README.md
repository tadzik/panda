# Panda

Panda is a Perl 6 module manager.

## Deprecation notice

Panda is not maintained and developed anymore; please use
[zef](https://github.com/ugexe/zef.git) instead.

## Installation

> Note: the most common way to install panda is via
> [rakudobrew](https://github.com/tadzik/rakudobrew): `rakudobrew build panda`.
> The instructions below are for installing it manually.

To install Panda along with all its dependencies, simply run the script
`bootstrap.pl` in the root of the panda git repo. You must have `perl6`
installed in order to run `bootstrap.pl`.

    git clone --recursive git://github.com/tadzik/panda.git

    cd panda

    perl6 bootstrap.pl

Since the bootstrap step currently runs tests with `prove`, you will need a
recent `TAP::Harness` (3.x) for it to work properly.

After a successful bootstrap, a message will appear saying which path should
be added to the `PATH` env variable in order to be able to run `panda` from
the command line. For example:

    ==> Please make sure that /home/user/rakudo/install/share/perl6/site/bin is in your PATH

If you use bash, you can fulfill that requirement with the following:

    echo "export PATH=\$PATH:$HOME/rakudo/install/share/perl6/site/bin" >> ~/.bashrc
    source ~/.bashrc

## Running Tests

One way to run the test suite is with `prove` from `TAP::Harness`

    prove -e perl6 -lrv t/
    # or on windows: prove -e "perl6 -lrv" t/

## Usage

Panda can be used like:

    panda install Task::Star

([Task::Star](https://github.com/tadzik/Task-Star/) is a handy bundle that
installs all the modules shipped with the Rakudo Star Perl 6 distribution.)

Alternatively, you can install a package from the local disk by supplying
its path:

    panda install ./perl6-Acme-Meow

Or, similarly to `cpanm` you can install all dependencies by specifying
simply the current directory:

    panda install .

You can also specify a git repository and panda will automatically fetch the
code from it. It's also possible to specify a commit to checkout:

    panda install git://github.com/tadzik/Net--IRC.git
    # or
    panda install git://github.com/tadzik/Net--IRC.git@3c5ca0db791d9ec

If you are behind a proxy, you need to [configure
git](http://help.github.com/firewalls-and-proxies/) and have
`HTTP::UserAgent` installed which supports proxies. Panda's built-in HTTP
client does not.

You can also use the `GIT_PROTOCOL` environment variable to specify another
protocol if git is blocked on your network:

    GIT_PROTOCOL=https panda install Acme::Meow

[1] http://help.github.com/firewalls-and-proxies/

[2] http://www.gnu.org/software/wget/manual/html_node/Proxies.html
