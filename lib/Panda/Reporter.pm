class Panda::Reporter;

has $.bone is rw;

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
