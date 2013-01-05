# Panda

![Panda](http://modules.perl6.org/panda.png) Panda is an implementation of a Perl 6 module manager specification.

## Description

Pies is a module management solution for Perl 6.
Pies itself is a specification (like masak's [Pls](https://github.com/masak/proto/tree/pls)), and cannot
install anything itself. The project ships two implementations:
ufobuilder, being an extremely simple example implementation of Pies,
and Panda, being the actual module manager to use.

## Installation on Linux/UNIX/OSX

To install Panda along with all its dependencies, simply run the script
bootstrap.pl in the root of the panda git repo. You must have
perl6 installed in order to run bootstrap.pl

    git clone git://github.com/tadzik/panda.git

    cd panda

    perl6 bootstrap.pl

Since the bootstrap step currently runs tests with prove, you will need a
recent TAP::Harness (3.x) for it to work properly.

If you are behind a proxy, you need to [configure git](http://help.github.com/firewalls-and-proxies/)
and [configure wget](http://www.gnu.org/software/wget/manual/html_node/Proxies.html) to use the proxy.

## Installation on Windows

Panda currently depends on wget; you can obtain a Windows build of wget at:

    http://gnuwin32.sourceforge.net/packages/wget.htm

Once you have obtained and installed it, and have both wget and perl6 in
your path, you may now install Panda by doing:

    git clone git://github.com/tadzik/panda.git

    cd panda

    perl6 bootstrap.pl

## Running Tests

One way to run the test suite is with prove from TAP::Harness

    prove -e perl6 -lrv t/

You will need a recent TAP::Harness (3.x) to have a prove binary with an -e option.

## Usage

Panda can be used like:

    panda install Acme::Meow

Alternatively, you can install a package from the local disk by supplying its path:

    panda install ./perl6-Acme-Meow

Note that ~/.perl6/bin has to be in your $PATH for you to be able to use
panda from the command line.

If you use bash, you can accomplish this with

    echo 'export PATH=$PATH:~/.perl6/bin' >> ~/.bashrc
    source ~/.bashrc

[1] https://github.com/masak/proto/tree/pls
[2] http://help.github.com/firewalls-and-proxies/
[3] http://www.gnu.org/software/wget/manual/html_node/Proxies.html
