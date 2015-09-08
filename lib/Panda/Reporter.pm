class Panda::Reporter {

has $.bone is rw;
has $.reports-file is rw;

method submit {
    if %*ENV<PANDA_SUBMIT_TESTREPORTS> {
        my $report-line = join "\t", $!bone.name,
                                    ($!bone.metainfo<authority> // $!bone.metainfo<author> // $!bone.metainfo<auth> // ''),
                                    ($!bone.version // '*'),
                                    ($!bone.build-passed // ''), ($!bone.test-passed // ''),
                                     $*VM.name;

        if $!reports-file.e && $!reports-file.slurp.match(/^^ $report-line \t $<report-id>=[\d+] $$/) -> $/ {
            say "==> Test report is duplicate of: http://testers.perl6.org/reports/$<report-id>.html";
            return
        }

        my $s;
        my $to-send = '';
        if %*ENV<http_proxy> {
            my ($host, $port) = %*ENV<http_proxy>.split('/').[2].split(':');
            $s                = IO::Socket::INET.new( :$host, :port($port.Int) );
            $to-send          = "POST http://testers.perl6.org/report HTTP/1.1\nHost: testers.perl6.org\nConnection: Close";
        }
        else {
            $s       = IO::Socket::INET.new(:host<213.95.82.53>, :port(80));
            $to-send = "POST http://testers.perl6.org/report HTTP/1.1\nHost: testers.perl6.org\nConnection: Close";
        }

        my $buf = Buf.new(self.to-json.ords);
        $s.print("$to-send\nContent-Type: application/json\r\nContent-Length: $buf.elems()\r\n\r\n");
        $s.write($buf);

        my $report-id = '';
        if $s.?lines -> @lines {
            $report-id = @lines[*-1];
            say "==> Test report submitted as: http://testers.perl6.org/reports/$report-id.html";
        }

        my $fh = $!reports-file.open(:a);
        $fh.say: $report-line ~ "\t" ~ $report-id;
        $fh.close;

        CATCH {
            die "Could not submit test report: {$_.message}"
        }
    }
}

method to-json {
    to-json {
        :name($!bone.name),
        :version($!bone.version),
        :dependencies($!bone.dependencies),
        :metainfo($!bone.metainfo),
        :build-output($!bone.build-output),
        :build-passed($!bone.build-passed),
        :test-output($!bone.test-output),
        :test-passed($!bone.test-passed),
        :distro({
            :name($*DISTRO.name),
            :version($*DISTRO.version.Str),
            :auth($*DISTRO.auth),
            :release($*DISTRO.release),
        }),
        :kernel({
            :name($*KERNEL.name),
            :version($*KERNEL.version.Str),
            :auth($*KERNEL.auth),
            :release($*KERNEL.release),
            :hardware($*KERNEL.hardware),
            :arch($*KERNEL.arch),
            :bits($*KERNEL.bits),
        }),
        :perl({
            :name($*PERL.name),
            :version($*PERL.version.Str),
            :auth($*PERL.auth),
            :compiler({
                :name($*PERL.compiler.name),
                :version($*PERL.compiler.version.Str),
                :auth($*PERL.compiler.auth),
                :release($*PERL.compiler.release),
                :build-date($*PERL.compiler.build-date.Str),
                :codename($*PERL.compiler.codename),
            }),
        }),
        :vm({
            :name($*VM.name),
            :version($*VM.version.Str),
            :auth($*VM.auth),
            :config($*VM.config),
            :properties($*VM.?properties),
            :precomp-ext($*VM.precomp-ext),
            :precomp-target($*VM.precomp-target),
            :prefix($*VM.prefix.Str),
        }),
    }, :pretty;
}

}

# vim: ft=perl6
