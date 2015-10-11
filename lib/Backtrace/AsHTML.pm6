use v6;
use MONKEY-TYPING;

unit class Backtrace::AsHTML;

augment class Backtrace {
    method as-html(*%opt) {
        say render(self, %opt);
    }
};

my sub render(Backtrace $bt, %opt) returns Str {
    my $traces = $bt.reverse;

    my $msg = encode-html($traces[0].Str.chomp);
    my $out = sprintf '<!doctype html><head><title>Error: %s</title>', $msg;

    %opt<style> ||= q:heredoc/STYLE/;
    a.toggle { color: #444 }
    body { margin: 0; padding: 0; background: #fff; color: #000; }
    h1 { margin: 0 0 .5em; padding: .25em .5em .1em 1.5em; border-bottom: thick solid #002; background: #444; color: #eee; font-size: x-large; }
    pre.message { margin: .5em 1em; }
    li.frame { font-size: small; margin-top: 3em }
    li.frame:nth-child(1) { margin-top: 0 }
    pre.context { border: 1px solid #aaa; padding: 0.2em 0; background: #fff; color: #444; font-size: medium; }
    pre .match { color: #000;background-color: #f99; font-weight: bold }
    pre.vardump { margin:0 }
    pre code strong { color: #000; background: #f88; }

    table.lexicals, table.arguments { border-collapse: collapse }
    table.lexicals td, table.arguments td { border: 1px solid #000; margin: 0; padding: .3em }
    table.lexicals tr:nth-child(2n) { background: #DDDDFF }
    table.arguments tr:nth-child(2n) { background: #DDFFDD }
    .lexicals, .arguments { display: none }
    .variable, .value { font-family: monospace; white-space: pre }
    td.variable { vertical-align: top }
    STYLE

    $out ~= sprintf '<style type="text/css">%s</style>', %opt<style>;

    $out ~= sprintf q:heredoc/HEAD/, $msg;
    <script language="JavaScript" type="text/javascript">
    function toggleThing(ref, type, hideMsg, showMsg) {
        var css = document.getElementById(type+'-'+ref).style;
        css.display = css.display == 'block' ? 'none' : 'block';

        var hyperlink = document.getElementById('toggle-'+ref);
        hyperlink.textContent = css.display == 'block' ? hideMsg : showMsg;
    }

    function toggleArguments(ref) {
        toggleThing(ref, 'arguments', 'Hide function arguments', 'Show function arguments');
    }

    function toggleLexicals(ref) {
        toggleThing(ref, 'lexicals', 'Hide lexical variables', 'Show lexical variables');
    }
    </script>
    </head>
    <body>
    <h1>Error trace</h1><pre class="message">%s</pre><ol>
    HEAD

    my $i = 0;
    for @$traces -> Backtrace::Frame $frame {
        say $frame.my;

        $i++;
        my Backtrace::Frame $next-frame = $traces[$i]; # peek next

        $out ~= join(
            '',
            '<li class="frame">',
            ($next-frame && $next-frame.subname) ?? encode-html("in " ~ $next-frame.subname) !! '',
            ' at ',
            $frame.file ?? encode-html($frame.file) !! '',
            ' line ',
            $frame.line,
            '<pre class="context"><code>',
            build-context($frame) || '',
            '</code></pre>',
            '</li>',
        );
    }

    $out ~= '</ol>';
    $out ~= '</body></html>';

    return $out;
}

my sub build-context(Backtrace::Frame $frame) returns Str {
    my $file    = $frame.file;
    my $linenum = $frame.line;

    my Str $code;
    if $file.IO.f {
        my $start = $linenum - 3;
        my $end   = $linenum + 3;
        $start = $start < 1 ?? 1 !! $start;

        my $fh = try { open $file, :bin } or die "cannot open $file: $!";
        my $cur-line = 0;

        unless $fh.eof {
            loop {
                my Str $line = $fh.get;
                last if $fh.eof;
                ++$cur-line;

                last if $cur-line > $end;
                next if $cur-line < $start;

                $line ~~ s:global/\t/        /;
                my @tag = $cur-line == $linenum ?? ['<strong class="match">', '</strong>']
                                                !! ['', ''];
                $code ~= sprintf "%s%5d: %s%s\n", @tag[0], $cur-line, encode-html($line), @tag[1];
            };
        }
        $fh.close;
    }

    return $code;
}

my sub encode-html(Str $str) {
    return $str.trans(
        [ '&',     '<',    '>',    '"',      q{'}    ] =>
        [ '&amp;', '&lt;', '&gt;', '&quot;', '&#39;' ]
    );
}

=begin pod

=head1 NAME

Backtrace::AsHTML - blah blah blah

=head1 SYNOPSIS

  use Backtrace::AsHTML;

=head1 DESCRIPTION

Backtrace::AsHTML is ...

=head1 AUTHOR

moznion <moznion@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 moznion

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
