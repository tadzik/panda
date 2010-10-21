class JSON::Tiny::Actions;

method TOP($/) {
    make $/.values.[0].ast;
};
method object($/) {
    # RAKUDO
    # the .item works around RT #78510
    make $<pairlist>.ast.hash.item ;
}

method pairlist($/) {
    # the .item works around RT #78510
    make $<pair>>>.ast.flat.item;
}

method pair($/) {
    make $<string>.ast => $<value>.ast;
}

method array($/) {
    make [$<value>>>.ast];
}

method string($/) {
    make join '', $/.caps>>.value>>.ast
}
method value:sym<number>($/) { make eval $/.Str }
method value:sym<string>($/) { make $<string>.ast }
method value:sym<true>($/)   { make Bool::True  }
method value:sym<false>($/)  { make Bool::False }
method value:sym<null>($/)   { make Any }
method value:sym<object>($/) { make $<object>.ast }
method value:sym<array>($/)  { make $<array>.ast }

method str($/)               { make ~$/ }

method str_escape($/) {
    if $<xdigit> {
        make chr(:16($<xdigit>.join));
    } else {
        my %h = '\\' => "\\",
                'n'  => "\n",
                't'  => "\t",
                'f'  => "\f",
                'r'  => "\r";
        make %h{~$/};
    }
}


# vim: ft=perl6
