# Panda

Panda is an implementation of a Perl 6 module manager specification.

## Description

Pies is a module management solution for Perl 6.
Pies itself is a specification (like masak's Pls[1]), and cannot
install anything itself. The project ships two implementations:
ufobuilder, being an extremely simple example implementation of Pies,
and Panda, being the actual module manager to use.

## Installation

To install Panda along with all its dependencies, simply run the script
bootstrap.sh in the root of the panda git repo. This requires that the
*perl6* binary to be in your $PATH.

This works good in *NIX environment.
However, some problems exist with installation in Windows environment
at the moment.

    git clone git://github.com/tadzik/panda.git

    cd panda

    sh ./bootstrap.sh

## Running Tests

## Usage

Panda can be used like:

$ panda install Acme::Meow

Note that ~/.perl6/bin has to be in your $PATH for you to be able to use
panda from the command line.

If you use bash, you can accomplish this with

    echo 'export PATH=$PATH:~/.perl6/bin' >> ~/.bashrc
    source ~/.bashrc

MORE

More features and docs on the way.

[1] https://github.com/masak/proto/tree/pls
