# INTERNAL MODULE: guts for CycleTuple type from Types::Standard.

package Types::Standard::CycleTuple;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Types::Standard::CycleTuple::AUTHORITY = 'cpan:TOBYINK';
	$Types::Standard::CycleTuple::VERSION   = '2.010001';
}

$Types::Standard::CycleTuple::VERSION =~ tr/_//d;

use Type::Tiny      ();
use Types::Standard ();
use Types::TypeTiny ();

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

my $_Optional = Types::Standard::Optional;
my $_arr      = Types::Standard::ArrayRef;
my $_Slurpy   = Types::Standard::Slurpy;

use Exporter::Tiny 1.004001 ();
our @ISA = qw( Exporter::Tiny );

sub _exporter_fail {
	my ( $class, $type_name, $values, $globals ) = @_;
	my $caller = $globals->{into};
	
	my @final;
	{
		my $to_type = sub {
			return $_[0] if Types::TypeTiny::is_TypeTiny($_[0]);
			require Type::Utils;
			Type::Utils::dwim_type( $_[0], for => 'caller' );
		};
		my $of = $values->{of};
		Types::TypeTiny::is_ArrayLike($of)
			or _croak( qq{Expected arrayref option "of" for type "$type_name"} );
		@final = map { $to_type->($_) } @$of;
	}
	
	my $type = Types::Standard::CycleTuple->of( @final );
	$type = $type->create_child_type(
		name => $type_name,
		$type->has_coercion ? ( coercion => 1 ) : (),
		exists( $values->{where} ) ? ( constraint => $values->{where} ) : (),
	);
	
	$INC{'Type/Registry.pm'}
		? 'Type::Registry'->for_class( $caller )->add_type( $type, $type_name )
		: ( $Type::Registry::DELAYED{$caller}{$type_name} = $type )
		unless( ref($caller) or $caller eq '-lexical' or $globals->{'lexical'} );
	return map +( $_->{name} => $_->{code} ), @{ $type->exportables };
}

no warnings;

my $cycleuniq = 0;

sub __constraint_generator {
	my @params = map {
		my $param = $_;
		Types::TypeTiny::is_TypeTiny( $param )
			or _croak(
			"Parameters to CycleTuple[...] expected to be type constraints; got $param" );
		$param;
	} @_;
	my $count = @params;
	my $tuple = Types::Standard::Tuple()->of( @params );
	
	_croak( "Parameters to CycleTuple[...] cannot be optional" )
		if grep !!$_->is_strictly_a_type_of( $_Optional ), @params;
	_croak( "Parameters to CycleTuple[...] cannot be slurpy" )
		if grep !!$_->is_strictly_a_type_of( $_Slurpy ), @params;
	
	sub {
		my $value = shift;
		return unless $_arr->check( $value );
		return if @$value % $count;
		my $i = 0;
		while ( $i < $#$value ) {
			my $tmp = [ @$value[ $i .. $i + $count - 1 ] ];
			return unless $tuple->check( $tmp );
			$i += $count;
		}
		!!1;
	}
} #/ sub __constraint_generator

sub __inline_generator {
	my @params = map {
		my $param = $_;
		Types::TypeTiny::is_TypeTiny( $param )
			or _croak(
			"Parameter to CycleTuple[`a] expected to be a type constraint; got $param" );
		$param;
	} @_;
	my $count = @params;
	my $tuple = Types::Standard::Tuple()->of( @params );
	
	return unless $tuple->can_be_inlined;
	
	sub {
		$cycleuniq++;
		
		my $v      = $_[1];
		my @checks = $_arr->inline_check( $v );
		push @checks, sprintf(
			'not(@%s %% %d)',
			( $v =~ /\A\$[a-z0-9_]+\z/i ? $v : "{$v}" ),
			$count,
		);
		push @checks, sprintf(
			'do { my $cyclecount%d = 0; my $cycleok%d = 1; while ($cyclecount%d < $#{%s}) { my $cycletmp%d = [@{%s}[$cyclecount%d .. $cyclecount%d+%d]]; unless (%s) { $cycleok%d = 0; last; }; $cyclecount%d += %d; }; $cycleok%d; }',
			$cycleuniq,
			$cycleuniq,
			$cycleuniq,
			$v,
			$cycleuniq,
			$v,
			$cycleuniq,
			$cycleuniq,
			$count - 1,
			$tuple->inline_check( "\$cycletmp$cycleuniq" ),
			$cycleuniq,
			$cycleuniq,
			$count,
			$cycleuniq,
		) if grep { $_->inline_check( '$xyz' ) ne '(!!1)' } @params;
		join( ' && ', @checks );
	}
} #/ sub __inline_generator

sub __deep_explanation {
	my ( $type, $value, $varname ) = @_;
	
	my @constraints =
		map Types::TypeTiny::to_TypeTiny( $_ ), @{ $type->parameters };
		
	if ( @$value % @constraints ) {
		return [
			sprintf(
				'"%s" expects a multiple of %d values in the array', $type,
				scalar( @constraints )
			),
			sprintf( '%d values found', scalar( @$value ) ),
		];
	}
	
	for my $i ( 0 .. $#$value ) {
		my $constraint = $constraints[ $i % @constraints ];
		next if $constraint->check( $value->[$i] );
		
		return [
			sprintf(
				'"%s" constrains value at index %d of array with "%s"', $type, $i, $constraint
			),
			@{
				$constraint->validate_explain(
					$value->[$i], sprintf( '%s->[%s]', $varname, $i )
				)
			},
		];
	} #/ for my $i ( 0 .. $#$value)
	
	# This should never happen...
	return;    # uncoverable statement
} #/ sub __deep_explanation

my $label_counter = 0;

sub __coercion_generator {
	my ( $parent, $child, @tuple ) = @_;
	
	my $child_coercions_exist = 0;
	my $all_inlinable         = 1;
	for my $tc ( @tuple ) {
		$all_inlinable = 0 if !$tc->can_be_inlined;
		$all_inlinable = 0 if $tc->has_coercion && !$tc->coercion->can_be_inlined;
		$child_coercions_exist++ if $tc->has_coercion;
	}
	
	return unless $child_coercions_exist;
	my $C = "Type::Coercion"->new( type_constraint => $child );
	
	if ( $all_inlinable ) {
		$C->add_type_coercions(
			$parent => Types::Standard::Stringable {
				my $label  = sprintf( "CTUPLELABEL%d", ++$label_counter );
				my $label2 = sprintf( "CTUPLEINNER%d", $label_counter );
				my @code;
				push @code, 'do { my ($orig, $return_orig, $tmp, @new) = ($_, 0);';
				push @code, "$label: {";
				push @code,
					sprintf(
					'(($return_orig = 1), last %s) if scalar(@$orig) %% %d != 0;', $label,
					scalar @tuple
					);
				push @code, sprintf( 'my $%s = 0; while ($%s < @$orig) {', $label2, $label2 );
				for my $i ( 0 .. $#tuple ) {
					my $ct        = $tuple[$i];
					my $ct_coerce = $ct->has_coercion;
					
					push @code, sprintf(
						'do { $tmp = %s; (%s) ? ($new[$%s + %d]=$tmp) : (($return_orig=1), last %s) };',
						$ct_coerce
						? $ct->coercion->inline_coercion( "\$orig->[\$$label2 + $i]" )
						: "\$orig->[\$$label2 + $i]",
						$ct->inline_check( '$tmp' ),
						$label2,
						$i,
						$label,
					);
				} #/ for my $i ( 0 .. $#tuple)
				push @code, sprintf( '$%s += %d;', $label2, scalar( @tuple ) );
				push @code, '}';
				push @code, '}';
				push @code, '$return_orig ? $orig : \\@new';
				push @code, '}';
				"@code";
			}
		);
	} #/ if ( $all_inlinable )
	
	else {
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				
				if ( scalar( @$value ) % scalar( @tuple ) != 0 ) {
					return $value;
				}
				
				my @new;
				for my $i ( 0 .. $#$value ) {
					my $ct = $tuple[ $i % @tuple ];
					my $x  = $ct->has_coercion ? $ct->coerce( $value->[$i] ) : $value->[$i];
					
					return $value unless $ct->check( $x );
					
					$new[$i] = $x;
				}
				
				return \@new;
			},
		);
	} #/ else [ if ( $all_inlinable ) ]
	
	return $C;
} #/ sub __coercion_generator

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Standard::CycleTuple - exporter utility for the B<CycleTuple> type constraint

=head1 SYNOPSIS

  use Types::Standard -types;
  
  # Normal way to validate a list of pairs of integers.
  #
  CycleTuple->of( Int, Int )->assert_valid( [ 7, 49, 8, 64 ] );
  
  use Types::Standard::CycleTuple IntPairs => { of => [ Int, Int ] },
  
  # Exported shortcut
  #
  assert_IntPairs [ 7, 49, 8, 64 ];

=head1 STATUS

This module is not covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

This is mostly internal code, but can also act as an exporter utility.

=head2 Exports

Types::Standard::CycleTuple can be used experimentally as an exporter.

  use Types::Standard 'Int';
  use Types::Standard::CycleTuple IntPairs => { of => [ Int, Int ] };

This will export the following functions into your namespace:

=over

=item C<< IntPairs >>

=item C<< is_IntPairs( $value ) >>

=item C<< assert_IntPairs( $value ) >>

=item C<< to_IntPairs( $value ) >>

=back

Multiple types can be exported at once:

  use Types::Standard -types;
  use Types::Standard::CycleTuple (
    IntIntPairs   => { of => [ Int, Int ] },
    StrIntPairs   => { of => [ Str, Int ] },
  );
  
  assert_StrIntPairs [ one => 1, two => 2 ];   # should not die

It's possible to further constrain the cycletuple using C<where>:

  use Types::Standard::CycleTuple MyThing => { of => [ ... ], where => sub { ... } };

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-type-tiny/issues>.

=head1 SEE ALSO

L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
