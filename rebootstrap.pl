#!/usr/bin/env perl6
use v6;

# Find old state file
my $home = $*OS eq 'MSWin32' ?? %*ENV<HOMEDRIVE> ~ %*ENV<HOMEPATH> !! %*ENV<HOME>;
my $state-file = "$home/.panda/state";

if not $state-file.IO.e {
    say "No need to rebootstrap, running normal bootstrap";
    run 'perl6 bootstrap.pl';
}

# Save a copy of the old state file to be written *after* bootstrapping again
my $old-state = slurp $state-file;

# Find modules that were installed by request
# (as opposed to just for dependency resolution)
my @modules;
given open($state-file) {
    for .lines() -> $line {
        my ($name, $state) = split /\s/, $line;
        next if $name eq any(<File::Tools JSON::Tiny Test::Mock panda>);
        if $state eq 'installed' {
            @modules.push: $name;
        }
    }
    .close;
}

# Clean old directories, boostrap a fresh panda,
# and reinstall all manually-installed modules
# TODO: Make me cross-platform
shell 'rm -rf ~/.perl6/lib';
shell 'rm -rf ~/.panda';
shell 'perl6 bootstrap.pl';
shell "panda install @modules[]";

# Save the backup state file back to ~/.panda/
spurt "$state-file.bak", $old-state if $old-state;
