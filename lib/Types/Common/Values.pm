package Types::Common::Values;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Types::Common::Values::AUTHORITY = 'cpan:TOBYINK';
	$Types::Common::Values::VERSION   = '2.010001';
	
	if ( $] >= 5.036 ) {
		require experimental;
		experimental->import( 'builtin' );
		*PRAGMATA        = sub () { 'use experimental qw(builtin)' };
		*FUNCTION_PREFIX = sub () { 'builtin::' };
	}
	else {
		*PRAGMATA = sub () { '' };
		eval sprintf q{sub FUNCTION_PREFIX () { '%s::_' }}, __PACKAGE__;
	}
	
	if ( eval 'use Scalar::Util 1.26; 1' ) {
		*_is_dual = \&Scalar::Util::isdual;
	}
	else {
		eval q{
			use B;
			sub _is_dual {
				my $f = B::svref_2object(\$_[0])->FLAGS;
				my $SVp_POK = eval { B::SVp_POK() } || 0;
				my $SVp_IOK = eval { B::SVp_IOK() } || 0;
				my $SVp_NOK = eval { B::SVp_NOK() } || 0;
				my $pok  = $f & ( B::SVf_POK | $SVp_POK );
				my $niok = $f & ( B::SVf_IOK | B::SVf_NOK | $SVp_IOK | $SVp_NOK );
				!!( $pok and $niok );
			}
		};
	}
};

use B                qw();
use Type::Library    qw( -base -declare BoolValue NumValue IntValue StrValue );
use Types::Standard  qw( Value Bool Str Num Int Overload );
use Types::TypeTiny  qw( BoolLike StringLike );
use utf8             qw();

sub _is_bool ($) {
	my $value = shift;
	return !!0 unless defined $value;
	return !!0 if ref $value;
	return !!0 unless _is_dual( $value );
	return !!1 if  $value && "$value" eq '1' && $value+0 == 1;
	return !!1 if !$value && "$value" eq q'' && $value+0 == 0;
	return !!0;
}

sub _created_as_number ($) {
	my $value = shift;
	return !!0 unless defined $value;
	return !!0 if ref $value;
	return !!0 if utf8::is_utf8($value);
	my $b_obj = B::svref_2object(\$value);
	my $flags = $b_obj->FLAGS;
	return !!1 if $flags & ( B::SVp_IOK() | B::SVp_NOK() ) and !( $flags & B::SVp_POK() );
	return !!0;
}

sub _created_as_string ($) {
	my $value = shift;
	defined($value)
		&& !ref($value)
		&& !_is_bool($value)
		&& !_created_as_number($value);
}

__PACKAGE__->add_type(
	name          => BoolValue,
	parent        => Value,
	type_default  => sub { !!0 },
	constraint    => sub { _is_bool(@_ ? $_[0] : $_) },
	inlined       => sub {
		return sprintf(
			'do { %s; %sis_bool(%s) }',
			PRAGMATA,
			FUNCTION_PREFIX,
			$_[1],
		) if PRAGMATA;
		return sprintf(
			'%sis_bool(%s)',
			FUNCTION_PREFIX,
			$_[1],
		);
	},
)->coercion->add_type_coercions(
	Bool,      q{!!($_)},
	BoolLike,  q{( ($_) ? !!1 : !!0 )},
);

__PACKAGE__->add_type(
	name          => NumValue,
	parent        => Value,
	type_default  => sub { 0 },
	constraint    => sub { _created_as_number(@_ ? $_[0] : $_) },
	inlined       => sub {
		return sprintf(
			'do { %s; %screated_as_number(%s) }',
			PRAGMATA,
			FUNCTION_PREFIX,
			$_[1],
		) if PRAGMATA;
		return sprintf(
			'%screated_as_number(%s)',
			FUNCTION_PREFIX,
			$_[1],
		);
	},
)->coercion->add_type_coercions(
	Num,                 q{( 0 + $_ )},
	Overload->of('0+'),  q{( 0 + sprintf( '%f', $_ ) )},
);

__PACKAGE__->add_type(
	name          => IntValue,
	parent        => NumValue,
	type_default  => sub { 0 },
	constraint    => sub { my $val = @_ ? $_[0] : $_; int($val)==$val },
	inlined       => sub {
		return sprintf(
			'do { %s; my $tmp = %s; %screated_as_number($tmp) and int($tmp)==$tmp }',
			PRAGMATA,
			$_[1],
			FUNCTION_PREFIX,
		);
	},
)->coercion->add_type_coercions(
	Int,                 q{( 0 + $_ )},
	Overload->of('0+'),  q{( 0 + sprintf( '%f', $_ ) )},
);

__PACKAGE__->add_type(
	name          => StrValue,
	parent        => Value,
	type_default  => sub { q{} },
	constraint    => sub { _created_as_string(@_ ? $_[0] : $_) },
	inlined       => sub {
		return sprintf(
			'do { %s; %screated_as_string(%s) }',
			PRAGMATA,
			FUNCTION_PREFIX,
			$_[1],
		) if PRAGMATA;
		return sprintf(
			'%screated_as_string(%s)',
			FUNCTION_PREFIX,
			$_[1],
		);
	},
)->coercion->add_type_coercions(
	Str,         q{( "" . $_ )},
	StringLike,  q{sprintf( '%s', $_ )},
);

__PACKAGE__->meta->make_immutable;

=pod

=encoding utf-8

=head1 NAME

Types::Common::Values - pedantic subtypes of B<Value>

=head1 STATUS

This module is covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

=head2 Types

This is a fairly small type library consisting of type constraints based
on the C<is_bool>, C<created_as_number>, and C<created_as_string> functions
from L<builtin>. Each type constraint is a subtype of B<Value> from
L<Types::Standard>.

It is rarely necessary to differentiate between C<< 1 >>, C<< "1" >>, and
C<< !!1 >> in Perl, but with this type constraint library you can.

These type constraints are not included in L<Types::Common>, but likely
will be in Type::Tiny 3.0.

=over

=item B<< BoolValue >>

Accepts only the Perl builtin boolean values. If you have a very recent
version of Perl, there are constants C<< builtin::false >> and
C<< builtin::true >>. On any version of Perl, you can use C<< !!0 >>
and C<< !!1 >> for true and false.

Unlike L<Bool> from L<Types::Standard>, does not accept C<undef>, nor the
strings C<< "0" >> and C<< "1" >>, nor the empty string, nor the numbers
C<< 0 >> and C<< 1 >>.

Coercions are defined from B<Bool> and B<BoolLike>.

=item B<< NumValue >>

Accepts only values which were created as numbers. So C<< 12 >> or
C<< 1.2 >> would pass the type constraint, but C<< "12" >> or
C<< "1.2" >> would not.

Coercions are defined from B<Num> and B<< Overload['0+'] >>.

=item B<< IntValue >>

A subtype of B<NumValue> which only accepts integers. Accepts C<< 7 >>
and C<< 7.0 >>, but not C<< "7" >> or C<< "7.0" >> or C<< 7.1 >>

This type isn't strictly necessary as it's possible to combine
B<NumValue> with types from L<Types::Common::Numeric> like
B<< NumValue & PositiveInt >>, however B<IntValue> seems like it
might be useful, so is provided as a convenience.

Coercions are defined from B<Int> and B<< Overload['0+'] >>.

=item B<< StrValue >>

Accepts only values which were created as strings. So C<< "Hello" >>
or C<< "" >> or C<< "7" >>, but not C<< 7 >> or undef or references.

Coercions are defined from B<Str> and B<StringLike>.

=back

It's worth noting that every possible scalar in Perl will validate
as one and only one of the following type constraints:
B<Undef>, B<Ref>, B<BoolValue>, B<NumValue>, and B<StrValue>.
These five type constraints are disjoint sets and between them
cover all possible Perl scalars.

(The dualvars which can be created using L<Scalar::Util> are a
complicated case, and may validate as B<BoolValue> or B<StrValue>,
depending on their string and numeric values, but will never
validate as both.)

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-type-tiny/issues>.

=head1 SEE ALSO

L<Types::Standard>, L<builtin>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
