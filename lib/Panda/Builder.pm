use Pies;
use Panda::Common;
use File::Find;
use Shell::Command;

class Panda::Builder does Pies::Builder {
    has $.resources;

    sub die (Pies::Project $p, $d) is hidden_from_backtrace {
        X::Panda.new($p.name, 'build', $d).throw
    }

    method build-order(@module-files) {
        my @modules = map { path-to-module-name($_) }, @module-files;
        my %module-to-path = @modules Z=> @module-files;
        my %usages_of;
        for @module-files -> $module-file {
            my $fh = open($module-file.Str, :r);
            my $module = path-to-module-name($module-file);
            %usages_of{$module} = [];
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

    method build(Pies::Project $p) {
        my $workdir = $!resources.workdir($p);
        return unless "$workdir/lib".IO ~~ :d;
        indir $workdir, {
            my @files = find(dir => 'lib', type => 'file').list;
            if "Build.pm".IO.f {
                @*INC.push('.');
                require 'Build';
                if ::('Build').isa(Panda::Builder) {
                    ::('Build').new(resources => $!resources).build($p);
                }
                @*INC.pop;
            }
            my @dirs = @files.map(*.dir).uniq;
            mkpath "blib/$_" for @dirs;

            my @tobuild = self.build-order(@files);
            withp6lib {
                for @tobuild -> $file {
                    $file.IO.copy: "blib/{$file.dir}/{$file.name}";
                    next unless $file ~~ /\.pm6?$/;
                    say "Compiling $file";
                    shell "$*EXECUTABLE_NAME --target=pir "
                        ~ "--output=blib/{$file.dir}/"
                        ~ "{$file.name.subst(/\.pm6?$/, '.pir')} $file"
                        and die $p, "Failed building $file";
                }
            }
        };
    }

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
}

# vim: ft=perl6
