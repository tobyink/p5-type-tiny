# INTERNAL MODULE: guts for StrMatch type from Types::Standard.

package Types::Standard::StrMatch;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Types::Standard::StrMatch::AUTHORITY = 'cpan:TOBYINK';
	$Types::Standard::StrMatch::VERSION   = '2.007_010';
}

$Types::Standard::StrMatch::VERSION =~ tr/_//d;

use Type::Tiny      ();
use Types::Standard ();
use Types::TypeTiny ();

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

use Exporter::Tiny 1.004001 ();
our @ISA = qw( Exporter::Tiny );

sub _exporter_fail {
	my ( $class, $type_name, $values, $globals ) = @_;
	my $caller = $globals->{into};
	
	my $of = exists( $values->{of} ) ? $values->{of} : $values->{re};
	Types::Standard::RegexpRef->assert_valid( $of );
	
	my $type = Types::Standard::StrMatch->of( $of );
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

our %expressions;
my $has_regexp_util;
my $serialize_regexp = sub {
	$has_regexp_util = eval {
		require Regexp::Util;
		Regexp::Util->VERSION( '0.003' );
		1;
	} || 0 unless defined $has_regexp_util;
	
	my $re = shift;
	my $serialized;
	if ( $has_regexp_util ) {
		$serialized = eval { Regexp::Util::serialize_regexp( $re ) };
	}
	
	unless ( defined $serialized ) {
		my $key = sprintf( '%s|%s', ref( $re ), $re );
		$expressions{$key} = $re;
		$serialized = sprintf(
			'$Types::Standard::StrMatch::expressions{%s}',
			B::perlstring( $key )
		);
	}
	
	return $serialized;
};

sub __constraint_generator {
	return Types::Standard->meta->get_type( 'StrMatch' ) unless @_;
	
	Type::Tiny::check_parameter_count_for_parameterized_type( 'Types::Standard', 'StrMatch', \@_, 2, 1 );
	my ( $regexp, $checker ) = @_;
	
	Types::Standard::is_RegexpRef( $regexp )
		or _croak(
		"First parameter to StrMatch[`a] expected to be a Regexp; got $regexp" );
		
	if ( @_ > 1 ) {
		$checker = Types::TypeTiny::to_TypeTiny( $checker );
		Types::TypeTiny::is_TypeTiny( $checker )
			or _croak(
			"Second parameter to StrMatch[`a] expected to be a type constraint; got $checker"
			);
	}
	
	$checker
		? sub {
			my $value = shift;
			return if !defined ( $value );
			return if ref( $value );
			my @m = ( $value =~ $regexp );
			$checker->check( \@m );
		}
		: sub {
			my $value = shift;
			defined( $value ) and !ref( $value ) and !!( $value =~ $regexp );
		};
} #/ sub __constraint_generator

sub __inline_generator {
	require B;
	my ( $regexp, $checker ) = @_;
	my $serialized_re = $regexp->$serialize_regexp or return;
	
	if ( $checker ) {
		return unless $checker->can_be_inlined;
		
		return sub {
			my $v = $_[1];
			if ( $Type::Tiny::AvoidCallbacks
				and $serialized_re =~ /Types::Standard::StrMatch::expressions/ )
			{
				require Carp;
				Carp::carp(
					"Cannot serialize regexp without callbacks; serializing using callbacks" );
			}
			sprintf
				"defined($v) and !ref($v) and do { my \$m = [$v =~ %s]; %s }",
				$serialized_re,
				$checker->inline_check( '$m' ),
				;
		};
	} #/ if ( $checker )
	else {
		my $regexp_string = "$regexp";
		if ( $regexp_string =~ /\A\(\?\^u?:\\A(\.+)\)\z/ ) {
			my $length = length $1;
			return sub { "defined($_) and !ref($_) and length($_)>=$length" };
		}
		
		if ( $regexp_string =~ /\A\(\?\^u?:\\A(\.+)\\z\)\z/ ) {
			my $length = length $1;
			return sub { "defined($_) and !ref($_) and length($_)==$length" };
		}
		
		return sub {
			my $v = $_[1];
			if ( $Type::Tiny::AvoidCallbacks
				and $serialized_re =~ /Types::Standard::StrMatch::expressions/ )
			{
				require Carp;
				Carp::carp(
					"Cannot serialize regexp without callbacks; serializing using callbacks" );
			}
			"defined($v) and !ref($v) and !!( $v =~ $serialized_re )";
		};
	} #/ else [ if ( $checker ) ]
} #/ sub __inline_generator

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Standard::StrMatch - exporter utility for the B<StrMatch> type constraint

=head1 SYNOPSIS

  use Types::Standard -types;
  
  # Normal way to validate a string against a regular expression.
  #
  StrMatch->of( qr/.../ )->assert_valid( "foo" );
  
  use Types::Standard::StrMatch Identifier => { re => qr/.../ },
  
  # Exported shortcut
  #
  assert_Identifier "foo";

=head1 STATUS

This module is not covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

This is mostly internal code, but can also act as an exporter utility.

=head2 Exports

Types::Standard::ScalarRef can be used experimentally as an exporter.

  use Types::Standard::StrMatch Identifier => { re => qr/.../ };

This will export the following functions into your namespace:

=over

=item C<< Identifier >>

=item C<< is_Identifier( $value ) >>

=item C<< assert_Identifier( $value ) >>

=item C<< to_Identifier( $value ) >>

=back

Multiple types can be exported at once:

  use Types::Standard -types;
  use Types::Standard::StrMatch (
    Identifier  => { re => qr/.../ },
    Url         => { re => qr/.../ },
	 Email       => { re => qr/.../ },
  );
  
  assert_Email 'tobyink@example.net';   # should not die

It's possible to further constrain the string using C<where>:

  use Types::Standard::StrMatch MyThing => { re => qr/.../, where => sub { ... } };

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
