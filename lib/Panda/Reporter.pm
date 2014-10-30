class Panda::Reporter;

has $.bone is rw;

method submit {
    if %*ENV<PANDA_SUBMIT_TESTREPORTS> {
        my $s;
        my $to-send = '';
        if %*ENV<http_proxy> {
            my ($host, $port) = %*ENV<http_proxy>.split('/').[2].split(':');
            $s                = IO::Socket::INET.new( :$host, :port($port.Int) );
            $to-send          = "POST http://127.0.0.1:3000/report HTTP/1.1\nHost: localhost\nConnection: Close";
        }
        else {
            $s       = IO::Socket::INET.new(:host<127.0.0.1>, :port(3000));
            $to-send = "POST /report HTTP/1.0";
        }

        my $buf = Buf.new(self.to-json.ords);
        $s.send("$to-send\nContent-Type: application/json\r\nContent-Length: $buf.elems()\r\n\r\n");
        $s.write($buf);

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
    }
}
