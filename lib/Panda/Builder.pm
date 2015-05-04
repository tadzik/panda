class Panda::Builder;
use Panda::Common;
use File::Find;
use Shell::Command;

sub path-to-module-name($path) {
    my $slash = / [ '/' | '\\' ]  /;
    $path.subst(/^'lib'<$slash>/, '').subst(/^'lib6'<$slash>/, '').subst(/\.pm6?$/, '').subst($slash, '::', :g);
}

#| Replace Pod lines with empty lines.
sub strip-pod(@in is rw, Str :$in-block? = '') {
    my @out;
    my $in-para = False;
    while @in.elems {
        my $line = @in.shift;

        if $in-para && $line ~~ /^\s*$/ {
            # End of paragraph
            $in-para = False;
            @out.push: $line;
            next;
        }
        if $in-block && $line ~~ /^\s* '=end' \s* $in-block / {
            # End of block
            @out.push: '';
            last;
        }

        if $line ~~ /^\s* '=begin' \s+ (<[\w\-]>+)/ && $0 -> $block-type {
            # Start of block
            $in-para = False;
            @out.push: '', |strip-pod(@in, :in-block($block-type.Str));
            next;
        }
        if $line ~~ /^\s* '='\w<[\w-]>* (\s|$)/ {
            # Start of paragraph
            $in-para = True;
            @out.push: '';
            next;
        }

        @out.push: ($in-para || $in-block) ?? '' !! $line;
    }
    @out;
}

sub build-order(@module-files) {
    my @modules = map { path-to-module-name($_) }, @module-files;
    my %module-to-path = @modules Z=> @module-files;
    my %usages_of;
    for @module-files -> $module-file {
        my $module = path-to-module-name($module-file);
        %usages_of{$module} = [];
        next unless $module-file.Str ~~ /\.pm6?$/; # don't try to "parse" non-perl files
        my @lines = strip-pod(slurp($module-file.Str).lines);
        for @lines {
            if /^\s* ['use'||'need'||'require'] \s+ (\w+ ['::' \w+]*)/ && $0 -> $used {
                next if $used eq 'v6';
                next if $used eq 'MONKEY_TYPING';

                %usages_of{$module}.push(~$used);
            }
        }
    }
    my @order = topo-sort(@modules, %usages_of);

    return map { %module-to-path{$_} }, @order;
}

method build($where, :$bone) {
    indir $where, {
        if "Build.pm".IO.f {
            @*INC.push("file#$where");   # TEMPORARY !!!
            GLOBAL::<Build>:delete;
            require 'Build.pm';
            if ::('Build').isa(Panda::Builder) {
                ::('Build').new.build($where);
            }
            @*INC.pop;
        }
        my @files;
        if 'lib'.IO.d {
            @files = find(dir => 'lib', type => 'file').for({
                my $io = .IO;
                $io if $io.basename.substr(0, 1) ne '.';
            });
        }
        my @dirs = @files.for(*.dirname).unique;
        mkpath "blib/$_" for @dirs;

        my @tobuild = build-order(@files);
        withp6lib {
            my $output = '';
            for @tobuild -> $file {
                $file.copy: "blib/$file";
                next unless $file ~~ /\.pm6?$/;
                my $dest = "blib/{$file.dirname}/"
                         ~ $file.basename ~ '.' ~ compsuffix ;
                #note "$dest modified: ", $dest.IO.modified;
                #note "$file modified: ", $file.IO.modified;
                #if $dest.IO.modified >= $file.IO.modified {
                #    say "$file already compiled, skipping";
                #    next;
                #}
                say "Compiling $file to {comptarget}";
                my $cmd    = "$*EXECUTABLE --target={comptarget} "
                           ~ "--output=$dest $file";
                $output ~= "$cmd\n";
                my $handle = pipe("$cmd 2>&1", :r);
                for $handle.lines {
                    .chars && .say;
                    $output ~= "$_\n";
                }
                my $passed = $handle.close.status == 0;

                if $bone {
                    $bone.build-output = $output;
                    $bone.build-passed = $passed;
                }
                fail "Failed building $file" unless $passed;
            }
            1;
        }
        1;
    };
    return True;
}

# vim: ft=perl6
