use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Types::Standard -types;
use Type::Params qw(compile);

my $x;
my $sub;
my $check;
my $e = exception {
	$sub = sub {
		$check = compile(Dict[key => Int]);
		$check->(@_);
	};
	$sub->({key => 'yeah'});
};

is($e->type->display_name, 'Dict[key=>Int]');

done_testing;
