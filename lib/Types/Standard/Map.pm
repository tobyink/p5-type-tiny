# INTERNAL MODULE: guts for Map type from Types::Standard.

package Types::Standard::Map;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Types::Standard::Map::AUTHORITY = 'cpan:TOBYINK';
	$Types::Standard::Map::VERSION   = '2.009_000';
}

$Types::Standard::Map::VERSION =~ tr/_//d;

use Type::Tiny      ();
use Types::Standard ();
use Types::TypeTiny ();

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

use Exporter::Tiny 1.004001 ();
our @ISA = qw( Exporter::Tiny );

sub _exporter_fail {
	my ( $class, $type_name, $values, $globals ) = @_;
	my $caller = $globals->{into};
	
	my ( $keys, $vals ) = exists( $values->{of} ) ? @{ $values->{of} } : ( $values->{keys}, $values->{values} );
	defined $keys or _croak( qq{Expected option "keys" for type "$type_name"} );
	defined $vals or _croak( qq{Expected option "values" for type "$type_name"} );
	
	if ( not Types::TypeTiny::is_TypeTiny($keys) ) {
		require Type::Utils;
		$keys = Type::Utils::dwim_type( $keys, for => $caller );
	}

	if ( not Types::TypeTiny::is_TypeTiny($vals) ) {
		require Type::Utils;
		$vals = Type::Utils::dwim_type( $vals, for => $caller );
	}
	
	my $type = Types::Standard::Map->of( $keys, $vals );
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

my $meta = Types::Standard->meta;

no warnings;

sub __constraint_generator {
	return $meta->get_type( 'Map' ) unless @_;
	
	Type::Tiny::check_parameter_count_for_parameterized_type( 'Types::Standard', 'Map', \@_, 2, 2 );
	my ( $keys, $values ) = @_;
	Types::TypeTiny::is_TypeTiny( $keys )
		or _croak(
		"First parameter to Map[`k,`v] expected to be a type constraint; got $keys" );
	Types::TypeTiny::is_TypeTiny( $values )
		or _croak(
		"Second parameter to Map[`k,`v] expected to be a type constraint; got $values"
		);
		
	my @xsub;
	if ( Type::Tiny::_USE_XS ) {
		my @known = map {
			my $known = Type::Tiny::XS::is_known( $_->compiled_check );
			defined( $known ) ? $known : ();
		} ( $keys, $values );
		
		if ( @known == 2 ) {
			my $xsub = Type::Tiny::XS::get_coderef_for( sprintf "Map[%s,%s]", @known );
			push @xsub, $xsub if $xsub;
		}
	} #/ if ( Type::Tiny::_USE_XS)
	
	sub {
		my $hash = shift;
		$keys->check( $_ )   || return for keys %$hash;
		$values->check( $_ ) || return for values %$hash;
		return !!1;
	}, @xsub;
} #/ sub __constraint_generator

sub __inline_generator {
	my ( $k, $v ) = @_;
	return unless $k->can_be_inlined && $v->can_be_inlined;
	
	my $xsubname;
	if ( Type::Tiny::_USE_XS ) {
		my @known = map {
			my $known = Type::Tiny::XS::is_known( $_->compiled_check );
			defined( $known ) ? $known : ();
		} ( $k, $v );
		
		if ( @known == 2 ) {
			$xsubname = Type::Tiny::XS::get_subname_for( sprintf "Map[%s,%s]", @known );
		}
	} #/ if ( Type::Tiny::_USE_XS)
	
	return sub {
		my $h = $_[1];
		return "$xsubname\($h\)" if $xsubname && !$Type::Tiny::AvoidCallbacks;
		my $p       = Types::Standard::HashRef->inline_check( $h );
		my $k_check = $k->inline_check( '$k' );
		my $v_check = $v->inline_check( '$v' );
		"$p and do { "
			. "my \$ok = 1; "
			. "for my \$v (values \%{$h}) { "
			. "(\$ok = 0, last) unless $v_check " . "}; "
			. "for my \$k (keys \%{$h}) { "
			. "(\$ok = 0, last) unless $k_check " . "}; " . "\$ok " . "}";
	};
} #/ sub __inline_generator

sub __deep_explanation {
	require B;
	my ( $type, $value, $varname ) = @_;
	my ( $kparam, $vparam ) = @{ $type->parameters };
	
	for my $k ( sort keys %$value ) {
		unless ( $kparam->check( $k ) ) {
			return [
				sprintf( '"%s" constrains each key in the hash with "%s"', $type, $kparam ),
				@{
					$kparam->validate_explain(
						$k, sprintf( 'key %s->{%s}', $varname, B::perlstring( $k ) )
					)
				},
			];
		} #/ unless ( $kparam->check( $k...))
		
		unless ( $vparam->check( $value->{$k} ) ) {
			return [
				sprintf( '"%s" constrains each value in the hash with "%s"', $type, $vparam ),
				@{
					$vparam->validate_explain(
						$value->{$k}, sprintf( '%s->{%s}', $varname, B::perlstring( $k ) )
					)
				},
			];
		} #/ unless ( $vparam->check( $value...))
	} #/ for my $k ( sort keys %$value)
	
	# This should never happen...
	return;    # uncoverable statement
} #/ sub __deep_explanation

sub __coercion_generator {
	my ( $parent, $child, $kparam, $vparam ) = @_;
	return unless $kparam->has_coercion || $vparam->has_coercion;
	
	my $kcoercable_item =
		$kparam->has_coercion
		? $kparam->coercion->_source_type_union
		: $kparam;
	my $vcoercable_item =
		$vparam->has_coercion
		? $vparam->coercion->_source_type_union
		: $vparam;
	my $C = "Type::Coercion"->new( type_constraint => $child );
	
	if ( ( !$kparam->has_coercion or $kparam->coercion->can_be_inlined )
		and ( !$vparam->has_coercion or $vparam->coercion->can_be_inlined )
		and $kcoercable_item->can_be_inlined
		and $vcoercable_item->can_be_inlined )
	{
		$C->add_type_coercions(
			$parent => Types::Standard::Stringable {
				my @code;
				push @code, 'do { my ($orig, $return_orig, %new) = ($_, 0);';
				push @code, 'for (keys %$orig) {';
				push @code,
					sprintf(
					'++$return_orig && last unless (%s);',
					$kcoercable_item->inline_check( '$_' )
					);
				push @code,
					sprintf(
					'++$return_orig && last unless (%s);',
					$vcoercable_item->inline_check( '$orig->{$_}' )
					);
				push @code, sprintf(
					'$new{(%s)} = (%s);',
					$kparam->has_coercion ? $kparam->coercion->inline_coercion( '$_' ) : '$_',
					$vparam->has_coercion
					? $vparam->coercion->inline_coercion( '$orig->{$_}' )
					: '$orig->{$_}',
				);
				push @code, '}';
				push @code, '$return_orig ? $orig : \\%new';
				push @code, '}';
				"@code";
			}
		);
	} #/ if ( ( !$kparam->has_coercion...))
	else {
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my %new;
				for my $k ( keys %$value ) {
					return $value
						unless $kcoercable_item->check( $k )
						&& $vcoercable_item->check( $value->{$k} );
					$new{ $kparam->has_coercion ? $kparam->coerce( $k ) : $k } =
						$vparam->has_coercion
						? $vparam->coerce( $value->{$k} )
						: $value->{$k};
				}
				return \%new;
			},
		);
	} #/ else [ if ( ( !$kparam->has_coercion...))]
	
	return $C;
} #/ sub __coercion_generator

sub __hashref_allows_key {
	my $self = shift;
	my ( $key ) = @_;
	
	return Types::Standard::is_Str( $key ) if $self == Types::Standard::Map();
	
	my $map = $self->find_parent(
		sub { $_->has_parent && $_->parent == Types::Standard::Map() } );
	my ( $kcheck, $vcheck ) = @{ $map->parameters };
	
	( $kcheck or Types::Standard::Any() )->check( $key );
} #/ sub __hashref_allows_key

sub __hashref_allows_value {
	my $self = shift;
	my ( $key, $value ) = @_;
	
	return !!0 unless $self->my_hashref_allows_key( $key );
	return !!1 if $self == Types::Standard::Map();
	
	my $map = $self->find_parent(
		sub { $_->has_parent && $_->parent == Types::Standard::Map() } );
	my ( $kcheck, $vcheck ) = @{ $map->parameters };
	
	( $kcheck or Types::Standard::Any() )->check( $key )
		and ( $vcheck or Types::Standard::Any() )->check( $value );
} #/ sub __hashref_allows_value

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Standard::Map - exporter utility for the B<Map> type constraint

=head1 SYNOPSIS

  use Types::Standard -types;
  
  # Normal way to validate map.
  #
  Map->of( Int, Str )->assert_valid( { 1 => "one" } );
  
  use Types::Standard::Map IntsToStrs => { keys => Int, values => Str },
  
  # Exported shortcut
  #
  assert_IntsToStrs { 1 => "one" };

=head1 STATUS

This module is not covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

This is mostly internal code, but can also act as an exporter utility.

=head2 Exports

Types::Standard::Map can be used experimentally as an exporter.

  use Types::Standard 'Int';
  use Types::Standard::Map IntsToStrs => { keys => Int, values => Str },

This will export the following functions into your namespace:

=over

=item C<< IntsToStrs >>

=item C<< is_IntsToStrs( $value ) >>

=item C<< assert_IntsToStrs( $value ) >>

=item C<< to_IntsToStrs( $value ) >>

=back

Multiple types can be exported at once:

  use Types::Standard -types;
  use Types::Standard::Map (
    IntsToStrs  => { keys => Int, values => Str },
    StrsToInts  => { keys => Str, values => Int },
  );
  
  assert_StrsToInts { two => 2 };   # should not die

It's possible to further constrain the hashref using C<where>:

  use Types::Standard::Dict MyThing => {
    keys   => Str->where( sub { ... } ),
    values => Int->where( sub { ... } ),
    where  => sub { ... },
  };

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
