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
use Test::Fatal;

use Types::Common -sigs, -types;

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
				{ named => [ LIST => ArrayRef, INDEX => Int ], goto_next => sub { my $arg = pop; ( undef, $arg->LIST, $arg->INDEX ) } },
				sub { return ( undef, ['helloworld'], 0 ) if ( $_[0] and $_[0] eq 'HELLOWORLD' ); die },
			],
		);
		
		my ( $self, $arr, $ix ) = &$sig;
		return $arr->[$ix];
	}

	subtest "signature( multi => [...] )" => sub {
		note signature(
			method => 1,
			multi  => [
				{ multi => [
					{ pos   => [ ArrayRef, Int ] },
					{ pos   => [ Int, ArrayRef ], goto_next => sub { @_[0, 2, 1] } },
				] },
				{ named => [ array => ArrayRef, index => Int, { alias => 'ix' } ], named_to_list => 1 },
				{ pos   => [ ArrayRef, Int ], method => 0, goto_next => sub { ( undef, @_ ) } },
				{ named => [ ARRAY => ArrayRef, INDEX => Int ], named_to_list => 1 },
				sub { return ( undef, ['helloworld'], 0 ) if ( $_[0] and $_[0] eq 'HELLOWORLD' ); die },
			],
			want_source => 1,
		);

		note signature(
			method => 1,
			multi  => [
				{ multi => [
					{ pos   => [ ArrayRef, Int ] },
					{ pos   => [ Int, ArrayRef ], goto_next => sub { @_[0, 2, 1] } },
				] },
				{ named => [ array => ArrayRef, index => Int, { alias => 'ix' } ], named_to_list => 1 },
				{ pos   => [ ArrayRef, Int ], method => 0, goto_next => sub { ( undef, @_ ) } },
				{ named => [ LIST => ArrayRef, INDEX => Int ], goto_next => sub { my $arg = pop; ( undef, $arg->LIST, $arg->INDEX ) } },
				sub { return ( undef, ['helloworld'], 0 ) if ( $_[0] and $_[0] eq 'HELLOWORLD' ); die },
			],
			want_object => 1,
		)->make_class_pp_code;

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
		
		is(
			__PACKAGE__->array_lookup( LIST => \@arr, INDEX => $ix ),
			$expect,
			'fifth alternative',
		);
		
		is(
			array_lookup( 'HELLOWORLD' ),
			'helloworld',
			'final alternative',
		);
		
		my $e = exception { array_lookup() };
		like $e, qr/Parameter validation failed/;
		
		is ${^_TYPE_PARAMS_MULTISIG}, undef;
	};
}

{
	signature_for array_lookup2 => (
		method => 1,
		multi  => [
			{ multi => [
				{ ID=>'first', pos   => [ ArrayRef, Int ] },
				{ ID=>'second', pos   => [ Int, ArrayRef ], goto_next => sub { @_[0, 2, 1] } },
			] },
			{ ID=>'third', named => [ array => ArrayRef, index => Int, { alias => 'ix' } ], named_to_list => 1 },
			{ ID=>'fourth', pos   => [ ArrayRef, Int ], method => 0, goto_next => sub { ( undef, @_ ) } },
			{ ID=>'fifth', named => [ LIST => ArrayRef, INDEX => Int ], goto_next => sub { my $arg = pop; ( undef, $arg->LIST, $arg->INDEX ) } },
			sub { return ( undef, ['helloworld'], 0 ) if ( $_[0] and $_[0] eq 'HELLOWORLD' ); die },
		],
	);
	
	sub array_lookup2 {
		my ( $self, $arr, $ix ) = @_;
		return $arr->[$ix];
	}
	
	subtest "signature_for function => ( multi => [...] )" => sub {
		
		my @arr    = qw( foo bar baz quux );
		my $ix     = 2;
		my $expect = 'baz';
		
		is(
			__PACKAGE__->array_lookup2( \@arr, $ix ),
			$expect,
			'first alternative',
		);
		
		is ${^_TYPE_PARAMS_MULTISIG}, 0;
		
		is(
			__PACKAGE__->array_lookup2( $ix, \@arr ),
			$expect,
			'second alternative',
		);
		
		is ${^_TYPE_PARAMS_MULTISIG}, 0;
		
		is(
			__PACKAGE__->array_lookup2( array => \@arr, index => $ix ),
			$expect,
			'third alternative (hash)',
		);
		
		is ${^_TYPE_PARAMS_MULTISIG}, 1;
		
		is(
			__PACKAGE__->array_lookup2( { array => \@arr, index => $ix } ),
			$expect,
			'third alternative (hashref)',
		);
		
		is ${^_TYPE_PARAMS_MULTISIG}, 1;
		
		is(
			__PACKAGE__->array_lookup2( array => \@arr, ix => $ix ),
			$expect,
			'third alternative (hash, alias)',
		);
		
		is ${^_TYPE_PARAMS_MULTISIG}, 1;
		
		is(
			__PACKAGE__->array_lookup2( { array => \@arr, ix => $ix } ),
			$expect,
			'third alternative (hashref, alias)',
		);
		
		is ${^_TYPE_PARAMS_MULTISIG}, 1;
		
		is(
			array_lookup2( \@arr, $ix ),
			$expect,
			'fourth alternative',
		);
		
		is ${^_TYPE_PARAMS_MULTISIG}, 2;
		
		is(
			__PACKAGE__->array_lookup2( LIST => \@arr, INDEX => $ix ),
			$expect,
			'fifth alternative',
		);
		
		is ${^_TYPE_PARAMS_MULTISIG}, 3;
		
		is(
			array_lookup2( 'HELLOWORLD' ),
			'helloworld',
			'final alternative',
		);
		
		is ${^_TYPE_PARAMS_MULTISIG}, 4;
		
		my $e = exception { array_lookup() };
		like $e, qr/Parameter validation failed/;
		
		is ${^_TYPE_PARAMS_MULTISIG}, undef;
	};
}

{
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
	subtest "signature( named => ..., pos => ..., multi => 1 )" => sub {
		note signature(
			named => [ { goto_next => sub { shift->foo } }, foo => Int, { alias => 'foolish' } ],
			pos   => [ Int ],
			multi => 1,
			want_source => 1,
		);
		
		is xyz( foo => 666 ), 666;
		is ${^_TYPE_PARAMS_MULTISIG}, 0;
		
		is xyz( { foolish => 999 } ), 999;
		is ${^_TYPE_PARAMS_MULTISIG}, 0;
		
		is xyz(42), 42;
		is ${^_TYPE_PARAMS_MULTISIG}, 1;
	};
}

my $e = exception {
	signature multiple => [ 123 ];
};
like $e, qr/Alternative signatures must be CODE, HASH, or ARRAY refs/;

done_testing;
