use Test;

class Test::Mock::Log {
    has @!log-entries;

    method log-method-call($name, $capture) {
        @!log-entries.push({ :$name, :$capture });
    }

    method called($name, :$times, :$with) {
        # Extract calls of the matching name.
        my @calls = @!log-entries.grep({ .<name> eq $name });

        # If we've an argument filter, apply it; we smart-match
        # everything but captures, which we eqv.
        my $with-args-note = "";
        if defined($with) {
            if $with ~~ Capture {
                @calls .= grep({ .<capture> eqv $with });
            }
            else {
                @calls .= grep({ .<capture> ~~ $with });
            }
            $with-args-note = " with arguments matching $with.perl()";
        }

        # Enforce times parameter, if given.
        if defined($times) {
            my $times-msg =
                $times == 0 ?? "never called $name" !!
                $times == 1 ?? "called $name 1 time" !!
                               "called $name $times times";
            is +@calls, $times, "$times-msg$with-args-note";
        }
        else {
            ok ?@calls, "called $name$with-args-note";
        }
    }

    method never-called($name, :$with) {
        self.called($name, times => 0, :$with);
    }
};

module Test::Mock {
    sub mocked($type, :%returning = {}) is export {
        # Generate a subclass that logs each method call.
        my %already-seen = :new;
        my $mocker = ClassHOW.new;
        $mocker.^add_parent($type.WHAT);
        for $type, $type.^parents() -> $p {
            last if $p === Mu;
            for $p.^methods(:local) -> $m {
                unless %already-seen{$m.name} {
                    $mocker.^add_method($m.name, method (|$c) {
                        $!log.log-method-call($m.name, $c);
                        %returning{$m.name} ~~ List ??
                            @(%returning{$m.name}) !!
                            %returning{$m.name}
                    });
                    %already-seen{$m.name} = True;
                }
            }
        }

        # Add log attribute and a method to access it.
        $mocker.^add_attribute(Attribute.new( name => '$!log', has_accessor => False ));
        $mocker.^add_method('!mock_log', method { $!log });

        # Return a mock object.
        my $mocked = $mocker.^compose();
        return $mocked.new(log => Test::Mock::Log.new());
    }

    sub check-mock($mock, *@checker) is export {
        .($mock!mock_log) for @checker;
    }
}
