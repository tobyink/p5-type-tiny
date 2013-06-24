use strict;
use warnings;
use Test::More;

use Data::Dump qw(pp);
use Eval::Closure qw(eval_closure);
use Sub::Quote;

my $quoted_sub = quote_sub q{ my ($a, $b) = @_; $a + $b + $fiddlefactor }, { '$fiddlefactor' => \0 };
is(
	$quoted_sub->(40, 2),
	42,
	"quoted sub works",
);


my $perl_string = quoted_from_sub($quoted_sub)->[1];
is(
	$perl_string,
	q{ my ($a, $b) = @_; $a + $b + $fiddlefactor },
	"can get original code back",
);

my $captures = quoted_from_sub($quoted_sub)->[2];
is_deeply(
	$captures,
	{ '$fiddlefactor' => \0 },
	"can get original captures back",
);

sub make_adder
{
	my $n = shift;
	
	my $code = join "\n", => (
		'sub {',
		'my $input = $_[0];',
		Sub::Quote::inlinify(
			$perl_string,
			join(q[,], '$input', pp($n)),
		),
		'}',
	);
	note($code);  # prove -v
	eval_closure(
		source      => $code,
		environment => $captures,
	);
}

my $add_seven = make_adder(7);
is(
	$add_seven->(35),
	42,
	"inlinify works",
);

done_testing;
