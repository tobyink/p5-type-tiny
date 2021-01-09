package Types::Standard::ScalarRef;

use 5.006001;
use strict;
use warnings;

BEGIN {
	$Types::Standard::ScalarRef::AUTHORITY = 'cpan:TOBYINK';
	$Types::Standard::ScalarRef::VERSION   = '1.012001';
}

$Types::Standard::ScalarRef::VERSION =~ tr/_//d;

use Types::Standard ();
use Types::TypeTiny ();

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

no warnings;

sub __constraint_generator {
	return Types::Standard::ScalarRef unless @_;
	
	my $param = shift;
	Types::TypeTiny::is_TypeTiny( $param )
		or _croak(
		"Parameter to ScalarRef[`a] expected to be a type constraint; got $param" );
		
	return sub {
		my $ref = shift;
		$param->check( $$ref ) || return;
		return !!1;
	};
} #/ sub __constraint_generator

sub __inline_generator {
	my $param = shift;
	return unless $param->can_be_inlined;
	return sub {
		my $v           = $_[1];
		my $param_check = $param->inline_check( "\${$v}" );
		"(ref($v) eq 'SCALAR' or ref($v) eq 'REF') and $param_check";
	};
}

sub __deep_explanation {
	my ( $type, $value, $varname ) = @_;
	my $param = $type->parameters->[0];
	
	for my $item ( $$value ) {
		next if $param->check( $item );
		return [
			sprintf(
				'"%s" constrains the referenced scalar value with "%s"', $type, $param
			),
			@{ $param->validate_explain( $item, sprintf( '${%s}', $varname ) ) },
		];
	}
	
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
				push @code, 'do { my ($orig, $return_orig, $new) = ($_, 0);';
				push @code, 'for ($$orig) {';
				push @code,
					sprintf(
					'++$return_orig && last unless (%s);',
					$coercable_item->inline_check( '$_' )
					);
				push @code,
					sprintf(
					'$new = (%s);',
					$param->coercion->inline_coercion( '$_' )
					);
				push @code, '}';
				push @code, '$return_orig ? $orig : \\$new';
				push @code, '}';
				"@code";
			}
		);
	} #/ if ( $param->coercion->...)
	else {
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my $new;
				for my $item ( $$value ) {
					return $value unless $coercable_item->check( $item );
					$new = $param->coerce( $item );
				}
				return \$new;
			},
		);
	} #/ else [ if ( $param->coercion->...)]
	
	return $C;
} #/ sub __coercion_generator

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Standard::ScalarRef - internals for the Types::Standard ScalarRef type constraint

=head1 STATUS

This module is considered part of Type-Tiny's internals. It is not
covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

This file contains some of the guts for L<Types::Standard>.
It will be loaded on demand. You may ignore its presence.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-type-tiny/issues>.

=head1 SEE ALSO

L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
