#!/usr/bin/env perl6

my %subtrees =
    'ext/File__Find'        => 'git://github.com/tadzik/File-Find.git',
    'ext/JSON__Fast'        => 'git://github.com/timo/json_fast.git',
    'ext/Shell__Command'    => 'git://github.com/tadzik/Shell-Command.git',
    ;

sub update-one(Str() $prefix is copy) {
    $prefix.=chop if substr($prefix, *-1) eq '/';
    my $url = %subtrees{$prefix} // die "$prefix is not a known subtree directory"
        ~ " (known dirs: { %subtrees.keys.sort.join: ', ' }";
    run 'git', 'subtree', 'pull', '--prefix', $prefix, $url, 'master', '--squash';
}

sub MAIN(Str $prefix) {
    if $prefix eq 'all' {
        update-one($_) for keys %subtrees;
    }
    else {
        update-one($prefix);
    }
}

# vim: ft=perl6
