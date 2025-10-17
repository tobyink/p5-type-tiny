# INTERNAL MODULE: guts for HashRef type from Types::Standard.

package Types::Standard::HashRef;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Types::Standard::HashRef::AUTHORITY = 'cpan:TOBYINK';
	$Types::Standard::HashRef::VERSION   = '2.008004';
}

$Types::Standard::HashRef::VERSION =~ tr/_//d;

use Type::Tiny      ();
use Types::Standard ();
use Types::TypeTiny ();

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

use Exporter::Tiny 1.004001 ();
our @ISA = qw( Exporter::Tiny );

sub _exporter_fail {
	my ( $class, $type_name, $values, $globals ) = @_;
	my $caller = $globals->{into};
	
	my $of = exists( $values->{of} ) ? $values->{of} : $values->{type};
	defined $of or _croak( qq{Expected option "of" for type "$type_name"} );
	if ( not Types::TypeTiny::is_TypeTiny($of) ) {
		require Type::Utils;
		$of = Type::Utils::dwim_type( $of, for => $caller );
	}
	
	my $type = Types::Standard::HashRef->of( $of );
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

sub __constraint_generator {
	return Types::Standard::HashRef unless @_;
	
	require Error::TypeTiny::WrongNumberOfParameters;
	Type::Tiny::check_parameter_count_for_parameterized_type( 'Types::Standard', 'HashRef', \@_, 1 );
	my $param = shift;
	Types::TypeTiny::is_TypeTiny( $param )
		or _croak(
		"Parameter to HashRef[`a] expected to be a type constraint; got $param" );
		
	my $param_compiled_check = $param->compiled_check;
	my $xsub;
	if ( Type::Tiny::_USE_XS ) {
		my $paramname = Type::Tiny::XS::is_known( $param_compiled_check );
		$xsub = Type::Tiny::XS::get_coderef_for( "HashRef[$paramname]" )
			if $paramname;
	}
	elsif ( Type::Tiny::_USE_MOUSE and $param->_has_xsub ) {
		require Mouse::Util::TypeConstraints;
		my $maker = "Mouse::Util::TypeConstraints"->can( "_parameterize_HashRef_for" );
		$xsub = $maker->( $param ) if $maker;
	}
	
	return (
		sub {
			my $hash = shift;
			$param->check( $_ ) || return for values %$hash;
			return !!1;
		},
		$xsub,
	);
} #/ sub __constraint_generator

sub __inline_generator {
	my $param = shift;
	
	my $compiled = $param->compiled_check;
	my $xsubname;
	if ( Type::Tiny::_USE_XS and not $Type::Tiny::AvoidCallbacks ) {
		my $paramname = Type::Tiny::XS::is_known( $compiled );
		$xsubname = Type::Tiny::XS::get_subname_for( "HashRef[$paramname]" );
	}
	
	return unless $param->can_be_inlined;
	return sub {
		my $v = $_[1];
		return "$xsubname\($v\)" if $xsubname && !$Type::Tiny::AvoidCallbacks;
		my $p           = Types::Standard::HashRef->inline_check( $v );
		my $param_check = $param->inline_check( '$i' );
		
		"$p and do { "
			. "my \$ok = 1; "
			. "for my \$i (values \%{$v}) { "
			. "(\$ok = 0, last) unless $param_check " . "}; " . "\$ok " . "}";
	};
} #/ sub __inline_generator

sub __deep_explanation {
	require B;
	my ( $type, $value, $varname ) = @_;
	my $param = $type->parameters->[0];
	
	for my $k ( sort keys %$value ) {
		my $item = $value->{$k};
		next if $param->check( $item );
		return [
			sprintf( '"%s" constrains each value in the hash with "%s"', $type, $param ),
			@{
				$param->validate_explain(
					$item, sprintf( '%s->{%s}', $varname, B::perlstring( $k ) )
				)
			},
		];
	} #/ for my $k ( sort keys %$value)
	
	# This should never happen...
	return;    # uncoverable statement
} #/ sub __deep_explanation

sub __coercion_generator {
	my ( $parent, $child, $param ) = @_;
	return unless $param->has_coercion;
	
	my $coercable_item = $param->coercion->_source_type_union;
	my $C              = "Type::Coercion"->new( type_constraint => $child );
	
	if ( $param->coercion->can_be_inlined and $coercable_item->can_be_inlined ) {
		$C->add_type_coercions(
			$parent => Types::Standard::Stringable {
				my @code;
				push @code, 'do { my ($orig, $return_orig, %new) = ($_, 0);';
				push @code, 'for (keys %$orig) {';
				push @code,
					sprintf(
					'$return_orig++ && last unless (%s);',
					$coercable_item->inline_check( '$orig->{$_}' )
					);
				push @code,
					sprintf(
					'$new{$_} = (%s);',
					$param->coercion->inline_coercion( '$orig->{$_}' )
					);
				push @code, '}';
				push @code, '$return_orig ? $orig : \\%new';
				push @code, '}';
				"@code";
			}
		);
	} #/ if ( $param->coercion->...)
	else {
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my %new;
				for my $k ( keys %$value ) {
					return $value unless $coercable_item->check( $value->{$k} );
					$new{$k} = $param->coerce( $value->{$k} );
				}
				return \%new;
			},
		);
	} #/ else [ if ( $param->coercion->...)]
	
	return $C;
} #/ sub __coercion_generator

sub __hashref_allows_key {
	my $self = shift;
	Types::Standard::is_Str( $_[0] );
}

sub __hashref_allows_value {
	my $self = shift;
	my ( $key, $value ) = @_;
	
	return !!0 unless $self->my_hashref_allows_key( $key );
	return !!1 if $self == Types::Standard::HashRef();
	
	my $href = $self->find_parent(
		sub { $_->has_parent && $_->parent == Types::Standard::HashRef() } );
	my $param = $href->type_parameter;
	
	Types::Standard::is_Str( $key ) and $param->check( $value );
} #/ sub __hashref_allows_value

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Standard::HashRef - exporter utility for the B<HashRef> type constraint

=head1 SYNOPSIS

  use Types::Standard -types;
  
  # Normal way to validate a hashref of integers.
  #
  HashRef->of( Int )->assert_valid( { one => 1 } );
  
  use Types::Standard::HashRef IntHash => { of => Int },
  
  # Exported shortcut
  #
  assert_IntHash { one => 1 };

=head1 STATUS

This module is not covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

This is mostly internal code, but can also act as an exporter utility.

=head2 Exports

Types::Standard::HashRef can be used experimentally as an exporter.

  use Types::Standard 'Int';
  use Types::Standard::HashRef IntHash => { of => Int };

This will export the following functions into your namespace:

=over

=item C<< IntHash >>

=item C<< is_IntHash( $value ) >>

=item C<< assert_IntHash( $value ) >>

=item C<< to_IntHash( $value ) >>

=back

Multiple types can be exported at once:

  use Types::Standard -types;
  use Types::Standard::HashRef (
    IntHash  => { of => Int },
    NumHash  => { of => Num },
    StrHash  => { of => Str },
  );
  
  assert_IntHash { two => 2 };   # should not die

It's possible to further constrain the hashref using C<where>:

  use Types::Standard::HashRef MyThing => { of => Int, where => sub { ... } };

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
