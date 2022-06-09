=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Eval::TypeTiny> supports alias=>1 using L<Devel::LexAlias>
implementation.

=head1 DEPENDENCIES

Requires Devel::LexAlias.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires 'Devel::LexAlias';

use Eval::TypeTiny;

Eval::TypeTiny::_force_implementation( Eval::TypeTiny::IMPLEMENTATION_DEVEL_LEXALIAS );

my %env = (
	'$foo' => do { my $x = "foo"; \$x },
	'@bar' => [ "bar" ],
	'%baz' => { "baz" => "1" },
);

my $source = <<'SRC';
sub {
	if (!@_) {
		return defined tied($foo);
	}
	return $foo if $_[0] eq '$foo';
	return @bar if $_[0] eq '@bar';
	return %baz if $_[0] eq '%baz';
	return;
}
SRC

my $closure = eval_closure(source => $source, environment => \%env, alias => 1);

ok(
	! $closure->(),
	'tied implementation was not used',
);

is_deeply(
	[ $closure->('$foo') ],
	[ 'foo' ],
	'closure over scalar',
);

is_deeply(
	[ $closure->('@bar') ],
	[ 'bar' ],
	'closure over array',
);

is_deeply(
	[ $closure->('%baz') ],
	[ 'baz' => 1 ],
	'closure over hash',
);

${ $env{'$foo'} } = 'FOO';
@{ $env{'@bar'} } = ('BAR');
%{ $env{'%baz'} } = ('BAZ' => 99);

is_deeply(
	[ $closure->('$foo') ],
	[ 'FOO' ],
	'closure over scalar - worked',
);

is_deeply(
	[ $closure->('@bar') ],
	[ 'BAR' ],
	'closure over array - worked',
);

is_deeply(
	[ $closure->('%baz') ],
	[ 'BAZ' => 99 ],
	'closure over hash - worked',
);


my $external = 40;
my $closure2 = eval_closure(
	source      => 'sub { $xxx += 2 }',
	environment => { '$xxx' => \$external },
	alias       => 1,
);

$closure2->();
is($external, 42, 'closing over variables really really really works!');

{
	my $destroyed = 0;
	
	{
		package MyIndicator;
		sub DESTROY { $destroyed++ }
	}
	
	{
		my $number = bless \(my $foo), "MyIndicator";
		$$number = 40;
		my $closure = eval_closure(
			source       => 'sub { $$xxx += 2 }',
			environment  => { '$xxx' => \$number },
			alias        => 1,
		);
		
		$closure->();
		
		is($$number, 42);
		is($destroyed, 0);
	}
	
	is($destroyed, 1, 'closed over variables disappear on cue');
}

if (0) {  # BROKEN
	my @store;
	
	{
		package MyTie;
		use Tie::Scalar ();
		our @ISA = 'Tie::StdScalar';
		sub STORE {
			my $self = shift;
			push @store, $_[0];
			$self->SUPER::STORE(@_);
		}
		sub method_of_mine { 42 }
	}
	
	tie(my($var), 'MyTie');
	
	$var = 1;
	
	my $closure = eval_closure(
		source       => 'sub { $xxx = $_[0]; tied($xxx)->method_of_mine }',
		environment  => { '$xxx' => \$var },
		alias        => 1,
	);
	
	is($closure->(2), 42, 'can close over tied variables ... AUTOLOAD stuff');
	$closure->(3);
	
	my $nother_closure = eval_closure(
		source       => 'sub { tied($xxx)->can(@_) }',
		environment  => { '$xxx' => \$var },
		alias        => 1,
	);
	
	ok( $nother_closure->('method_of_mine'), '... can');
	ok(!$nother_closure->('your_method'), '... !can');

	is_deeply(
		\@store,
		[ 1 .. 3],
		'... tie still works',
	);

	{
		package OtherTie;
		our @ISA = 'MyTie';
		sub method_of_mine { 666 }
	}
	
	tie($var, 'OtherTie');
	is($closure->(4), 666, '... can be retied');

	untie($var);
	my $e = exception { $closure->(5) };
	like($e, qr{^Can't call method "method_of_mine" on an undefined value}, '... can be untied');
}

if (0) {   # ALSO BROKEN
	my $e = exception { eval_closure(source => 'sub { 1 ]') };

	isa_ok(
		$e,
		'Error::TypeTiny::Compilation',
		'$e',
	);

	like(
		$e,
		qr{^Failed to compile source because: syntax error},
		'throw exception when code does not compile',
	);

	like(
		$e->errstr,
		qr{^syntax error},
		'$e->errstr',
	);

	like(
		$e->code,
		qr{sub \{ 1 \]},
		'$e->code',
	);

	my $c1 = eval_closure(source => 'sub { die("BANG") }', description => 'test1');
	my $e1 = exception { $c1->() };

	like(
		$e1,
		qr{^BANG at test1 line 1},
		'"description" option works',
	);

	my $c2 = eval_closure(source => 'sub { die("BANG") }', description => 'test2', line => 222);
	my $e2 = exception { $c2->() };

	like(
		$e2,
		qr{^BANG at test2 line 222},
		'"line" option works',
	);
}

done_testing;
