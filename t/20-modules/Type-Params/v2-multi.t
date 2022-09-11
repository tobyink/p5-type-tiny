=pod

=encoding utf-8

=head1 PURPOSE

Tests new C<multi> option in Type::Params.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Types::Common -sigs, -types;

note signature(
	method => 1,
	multi  => [
		{ multi => [
			{ pos   => [ ArrayRef, Int ] },
			{ pos   => [ Int, ArrayRef ], goto_next => sub { @_[0, 2, 1] } },
		] },
		{ named => [ array => ArrayRef, index => Int, { alias => 'ix' } ], named_to_list => 1 },
		{ pos   => [ ArrayRef, Int ], method => 0, goto_next => sub { ( undef, @_ ) } },
	],
	want_source => 1,
);

{
	my $sig;
	sub array_lookup {
		$sig ||= signature(
			method => 1,
			multi  => [
				{ multi => [
					{ pos   => [ ArrayRef, Int ] },
					{ pos   => [ Int, ArrayRef ], goto_next => sub { @_[0, 2, 1] } },
				] },
				{ named => [ array => ArrayRef, index => Int, { alias => 'ix' } ], named_to_list => 1 },
				{ pos   => [ ArrayRef, Int ], method => 0, goto_next => sub { ( undef, @_ ) } },
			],
		);
		
		my ( $self, $arr, $ix ) = &$sig;
		return $arr->[$ix];
	}
	
	my @arr    = qw( foo bar baz quux );
	my $ix     = 2;
	my $expect = 'baz';
	
	is(
		__PACKAGE__->array_lookup( \@arr, $ix ),
		$expect,
		'first alternative',
	);
	
	is(
		__PACKAGE__->array_lookup( $ix, \@arr ),
		$expect,
		'second alternative',
	);
	
	is(
		__PACKAGE__->array_lookup( array => \@arr, index => $ix ),
		$expect,
		'third alternative (hash)',
	);
	
	is(
		__PACKAGE__->array_lookup( { array => \@arr, index => $ix } ),
		$expect,
		'third alternative (hashref)',
	);
	
	is(
		__PACKAGE__->array_lookup( array => \@arr, ix => $ix ),
		$expect,
		'third alternative (hash, alias)',
	);
	
	is(
		__PACKAGE__->array_lookup( { array => \@arr, ix => $ix } ),
		$expect,
		'third alternative (hashref, alias)',
	);
	
	is(
		array_lookup( \@arr, $ix ),
		$expect,
		'fourth alternative',
	);
}

{
	note signature(
		named => [ { goto_next => sub { shift->foo } }, foo => Int, { alias => 'foolish' } ],
		pos   => [ Int ],
		multi => 1,
		want_source => 1,
	);
	
	my $sig;
	sub xyz {
		$sig ||= signature(
			named => [ { goto_next => sub { shift->foo } }, foo => Int, { alias => 'foolish' } ],
			pos   => [ Int ],
			multi => 1,
		);
		my ( $int ) = &$sig;
		return $int;
	}
	
	is xyz( foo => 666 ), 666;
	is ${^TYPE_PARAMS_MULTISIG}, 0;
	
	is xyz( { foolish => 999 } ), 999;
	is ${^TYPE_PARAMS_MULTISIG}, 0;
	
	is xyz(42), 42;
	is ${^TYPE_PARAMS_MULTISIG}, 1;
}

done_testing;
