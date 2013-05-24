class Panda::Builder;
use Panda::Common;
use File::Find;
use Shell::Command;

sub topo-sort(@modules, %dependencies) {
    my @order;
    my %color_of = @modules X=> 'not yet visited';
    sub dfs-visit($module) {
        %color_of{$module} = 'visited';
        for %dependencies{$module}.list -> $used {
            if (%color_of{$used} // '') eq 'not yet visited' {
                dfs-visit($used);
            }
        }
        push @order, $module;
    }

    for @modules -> $module {
        if %color_of{$module} eq 'not yet visited' {
            dfs-visit($module);
        }
    }
    @order;
}

sub path-to-module-name($path) {
    $path.subst(/^'lib/'/, '').subst(/^'lib6/'/, '').subst(/\.pm6?$/, '').subst('/', '::', :g);
}

sub build-order(@module-files) {
    my @modules = map { path-to-module-name($_) }, @module-files;
    my %module-to-path = @modules Z=> @module-files;
    my %usages_of;
    for @module-files -> $module-file {
        my $module = path-to-module-name($module-file);
        %usages_of{$module} = [];
        next unless $module-file.Str ~~ /\.pm6?$/; # don't try to "parse" non-perl files
        my $fh = open($module-file.Str, :r);
        for $fh.lines() {
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

method build($where) {
    indir $where, {
        my @files = find(dir => 'lib', type => 'file').grep({
            $_.name.substr(0, 1) ne '.'
        });
        if "Build.pm".IO.f {
            @*INC.push('.');
            require 'Build.pm';
            if ::('Build').isa(Panda::Builder) {
                ::('Build').new.build($where);
            }
            @*INC.pop;
        }
        my @dirs = @files.map(*.dir).uniq;
        mkpath "blib/$_" for @dirs;

        my @tobuild = build-order(@files);
        withp6lib {
            for @tobuild -> $file {
                $file.IO.copy: "blib/{$file.dir}/{$file.name}";
                next unless $file ~~ /\.pm6?$/;
                my $dest = "blib/{$file.dir}/"
                         ~ "{$file.name.subst(/\.pm6?$/, '.pir')}";
                #note "$dest modified: ", $dest.IO.modified;
                #note "$file modified: ", $file.IO.modified;
                #if $dest.IO.modified >= $file.IO.modified {
                #    say "$file already compiled, skipping";
                #    next;
                #}
                say "Compiling $file";
                shell "$*EXECUTABLE_NAME --target=pir "
                    ~ "--output=$dest $file"
                    and die "Failed building $file";
            }
            1;
        }
        1;
    };
}

# vim: ft=perl6
