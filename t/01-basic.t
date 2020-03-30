use v6;
use lib 'lib';
use Test;
use Backtrace::AsHTML;

plan 3;

my $html;

my sub foo(Str $arg) {
    my $t = Backtrace.new;
    $html = $t.as-html;
}

my sub bar(Int $arg) {
    foo("bar")
}
bar(2);

like $html, rx{'in block &lt;unit&gt; at t/01-basic.t line 18'};
like $html, rx{'in bar at t/01-basic.t line 18'};
like $html, rx{'in foo at t/01-basic.t line 16'};

done-testing;

