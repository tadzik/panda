class JSON::Tiny::Actions;

method TOP($/) {
    make $/.values.[0].ast;
};
method object($/) {
    make $<pairlist>.ast.hash;
}

method pairlist($/) {
    make $<pair>>>.ast.flat;
}

method pair($/) {
    make $<string>.ast => $<value>.ast;
}

method array($/) {
    make $<arraylist>.ast;
}

method arraylist($/) {
    make [$<value>>>.ast];
}

method string($/) {
    make +@$<str> == 1
        ?? $<str>[0].ast
        !! $<str>>>.ast.join;
}
method value:sym<number>($/) { make +$/.Str }
method value:sym<string>($/) { make $<string>.ast }
method value:sym<true>($/)   { make Bool::True  }
method value:sym<false>($/)  { make Bool::False }
method value:sym<null>($/)   { make Any }
method value:sym<object>($/) { make $<object>.ast }
method value:sym<array>($/)  { make $<array>.ast }

method str($/)               { make ~$/ }

my %h = '\\' => "\\",
        '/'  => "/",
        'b'  => "\b",
        'n'  => "\n",
        't'  => "\t",
        'f'  => "\f",
        'r'  => "\r",
        '"'  => "\"";
method str_escape($/) {
    if $<xdigit> {
        # make chr(:16($<xdigit>.join));  # preferred version of next line, but it doesn't work on Niecza yet
        make chr(eval "0x" ~ $<xdigit>.join);
    } else {
        make %h{~$/};
    }
}


# vim: ft=perl6
