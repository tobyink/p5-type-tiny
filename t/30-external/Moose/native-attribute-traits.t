=pod

=encoding utf-8

=head1 PURPOSE

Check type constraints and coercions work with L<Moose> native attibute
traits.

=head1 DEPENDENCIES

Test is skipped if Moose 2.1210 is not available.

(The feature should work in older versions of Moose, but older versions
of Test::Moose conflict with newer versions of Test::Builder.)

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
use Test::Requires { Moose => '2.1210' };
use Test::Fatal;
use Test::TypeTiny qw( matchfor );
use Test::Moose qw( with_immutable );

use Types::Standard -types;

# For testing Array trait
{
	package MyCollection;
	use Moose;
	use Types::Standard qw( ArrayRef Object );
	has things => (
		is      => 'ro',
		isa     => ArrayRef[ Object ],
		traits  => [ 'Array' ],
		handles => { add => 'push' },
	);
}

# for testing Hash trait
my %attributes = (
	hashref      => HashRef,
	hashref_int  => HashRef[Int],
	map          => Map,
	map_strint   => Map[Str, Int],
);
{
	package MyHashes;
	use Moose;
	while (my ($attr, $type) = each %attributes)
	{
		has $attr => (
			traits  => ['Hash'],
			is      => 'ro',
			isa     => $type,
			handles => {
				"$attr\_get" => 'get',
				"$attr\_set" => 'set',
				"$attr\_has" => 'exists',
			},
			default => sub { +{} },
		);
	}
}

# For testing coercions
{
	package Mini::Milk;
	use Moose;
	use Types::Standard qw( Int InstanceOf );
	has i => (is => 'ro', isa => Int);
	around BUILDARGS => sub {
		my $next  = shift;
		my $class = shift;
		return { i => $_[0] }
			if @_==1 and not ref $_[0];
		$class->$next(@_);
	}
}

my $minimilk = InstanceOf->of('Mini::Milk')->plus_constructors(Num, "new");

{
	package MyCollection2;
	use Moose;
	use Types::Standard qw( ArrayRef );
	has things => (
		is      => 'ro',
		isa     => ArrayRef[ $minimilk ],
		traits  => [ 'Array' ],
		handles => { add => 'push' },
		coerce  => 1,
	);
}
{
	package MyCollection3;
	use Moose;
	use Types::Standard qw( ArrayRef );
	has things => (
		is      => 'ro',
		isa     => (ArrayRef[ $minimilk ])->create_child_type(coercion => 1),
		traits  => [ 'Array' ],
		handles => { add => 'push' },
		coerce  => 1,
	);
}
{
	package MyHashes2;
	use Moose;
	use Types::Standard qw( HashRef Map Int );
	has hash => (
		traits  => ['Hash'],
		is      => 'ro',
		isa     => HashRef[ $minimilk ],
		coerce  => 1,
		handles => {
			"hash_get" => 'get',
			"hash_set" => 'set',
		},
		default => sub { +{} },
	);
	has 'map' => (
		traits  => ['Hash'],
		is      => 'ro',
		isa     => Map[ Int, $minimilk ],
		coerce  => 1,
		handles => {
			"map_get" => 'get',
			"map_set" => 'set',
		},
		default => sub { +{} },
	);
}
{
	package MyHashes3;
	use Moose;
	use Types::Standard qw( HashRef Map Int );
	has hash => (
		traits  => ['Hash'],
		is      => 'ro',
		isa     => (HashRef[ $minimilk ])->create_child_type(coercion => 1),
		coerce  => 1,
		handles => {
			"hash_get" => 'get',
			"hash_set" => 'set',
		},
		default => sub { +{} },
	);
	has 'map' => (
		traits  => ['Hash'],
		is      => 'ro',
		isa     => (Map[ Int, $minimilk ])->create_child_type(coercion => 1),
		coerce  => 1,
		handles => {
			"map_get" => 'get',
			"map_set" => 'set',
		},
		default => sub { +{} },
	);
}

WEIRD_ERROR: {
	my $c = MyCollection3
		->meta
		->get_attribute('things')
		->type_constraint
		->coercion
		->compiled_coercion;
	
	my $input     = [ Mini::Milk->new(0), 1, 2, 3 ];
	my $output   = $c->($input);
	my $expected = [ map Mini::Milk->new($_), 0..3 ];
	is_deeply($output, $expected)
		or diag( B::Deparse->new->coderef2text($c) );
}

my $i = 0;
with_immutable
{
	note($i++ ? "MUTABLE" : "IMMUTABLE");
	
	subtest "Array trait with type ArrayRef[Object]" => sub
	{
		my $coll = MyCollection->new(things => []);

		ok(
			!exception { $coll->add(bless {}, "Monkey") },
			'pushing ok value',
		);

		is(
			exception { $coll->add({})},
			matchfor(
				'Moose::Exception::ValidationFailedForInlineTypeConstraint',
				qr{^A new member value for things does not pass its type constraint because:},
			),
			'pushing not ok value',
		);
	};

	my %subtests = (
		MyCollection2  => "Array trait with type ArrayRef[InstanceOf] and coercion",
		MyCollection3  => "Array trait with type ArrayRef[InstanceOf] and coercion and subtyping",
	);
	for my $class (sort keys %subtests)
	{
		subtest $subtests{$class} => sub
		{
			my $coll = $class->new(things => []);
			
			is(
				exception {
					$coll->add( 'Mini::Milk'->new(i => 0) );
					$coll->add(1);
					$coll->add(2);
					$coll->add(3);
				},
				undef,
				'pushing ok values',
			);
			
			my $things = $coll->things;
			for my $i (0 .. 3)
			{
				isa_ok($things->[$i], 'Mini::Milk', "\$things->[$i]");
				is($things->[$i]->i, $i, "\$things->[$i]->i == $i");
			}
		};
	}
	
	for my $attr (sort keys %attributes)
	{
		my $type      = $attributes{$attr};
		my $getter    = "$attr\_get";
		my $setter    = "$attr\_set";
		my $predicate = "$attr\_has";
		
		subtest "Hash trait with type $type" => sub
		{
			my $obj = MyHashes->new;
			is_deeply($obj->$attr, {}, 'default empty hash');
			
			$obj->$setter(foo => 666);
			$obj->$setter(bar => 999);
			is($obj->$getter('foo'), 666, 'getter');
			is($obj->$getter('bar'), 999, 'getter');
			$obj->$setter(bar => 42);
			is($obj->$getter('bar'), 42, 'setter');
			ok($obj->$predicate('foo'), 'predicate');
			ok($obj->$predicate('bar'), 'predicate');
			ok(!$obj->$predicate('baz'), 'predicate - negatory');
			is_deeply($obj->$attr, { foo => 666, bar => 42 }, 'correct hash');
			
			like(
				exception { $obj->$setter(baz => 3.141592) },
				qr/type constraint/,
				'cannot add non-Int value',
			) if $attr =~ /int$/;
			
			done_testing;
		};
	}
	
	%subtests = (
		MyHashes2  => "Hash trait with types HashRef[InstanceOf] and Map[Int,InstanceOf]; and coercion",
		MyHashes3  => "Hash trait with types HashRef[InstanceOf] and Map[Int,InstanceOf]; and coercion and subtyping",
	);
	for my $class (sort keys %subtests)
	{
		subtest $subtests{$class} => sub
		{
			my $H = $class->new();

			is(
				exception {
					$H->hash_set( 0, 'Mini::Milk'->new(i => 0) );
					$H->hash_set( 1, 1 );
					$H->hash_set( 2, 2 );
					$H->hash_set( 3, 3 );
				},
				undef,
				'adding ok values to HashRef',
			);
			
			is(
				exception {
					$H->map_set( 4, 'Mini::Milk'->new(i => 4) );
					$H->map_set( 5, 5 );
					$H->map_set( 6, 6 );
					$H->map_set( 7, 7 );
				},
				undef,
				'adding ok values to Map',
			);
			
			my $h = $H->hash;
			for my $i (0 .. 3)
			{
				isa_ok($h->{$i}, 'Mini::Milk', "\$h->{$i}");
				is($h->{$i}->i, $i, "\$h->{$i}->i == .$i");
			}
			
			my $m = $H->map;
			for my $i (4 .. 7)
			{
				isa_ok($m->{$i}, 'Mini::Milk', "\$m->{$i}");
				is($m->{$i}->i, $i, "\$m->{$i}->i == .$i");
			}
		};
	}
} qw(
	MyCollection
	MyCollection2
	MyCollection3
	MyHashes
	Mini::Milk
);

done_testing;
