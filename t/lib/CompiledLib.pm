use 5.008001;
use strict;
use warnings;

package CompiledLib;

use Exporter ();
use Carp qw( croak );

our @ISA = qw( Exporter );
our @EXPORT;
our @EXPORT_OK;
our %EXPORT_TAGS = (
	is     => [],
	types  => [],
	assert => [],
);

BEGIN {
	package CompiledLib::TypeConstraint;
	our $LIBRARY = "CompiledLib";

	use overload (
		fallback => !!1,
		'|'      => 'union',
		bool     => sub { !! 1 },
		'""'     => sub { shift->[1] },
		'&{}'    => sub {
			my $self = shift;
			return sub { $self->assert_return( @_ ) };
		},
	);

	sub union {
		my @types = grep ref( $_ ), @_;
		my @codes = map $_->[0], @types;
		bless [
			sub { for ( @codes ) { return 1 if $_->(@_) } return 0 },
			join( '|', map $_->[1], @types ),
			\@types,
		], __PACKAGE__;
	}

	sub check {
		$_[0][0]->( $_[1] );
	}

	sub get_message {
		sprintf '%s did not pass type constraint "%s"',
			defined( $_[1] ) ? $_[1] : 'Undef',
			$_[0][1];
	}

	sub validate {
		$_[0][0]->( $_[1] )
			? undef
			: $_[0]->get_message( $_[1] );
	}

	sub assert_valid {
		$_[0][0]->( $_[1] )
			? 1
			: Carp::croak( $_[0]->get_message( $_[1] ) );
	}

	sub assert_return {
		$_[0][0]->( $_[1] )
			? $_[1]
			: Carp::croak( $_[0]->get_message( $_[1] ) );
	}

	sub to_TypeTiny {
		my ( $coderef, $name, $library, $origname ) = @{ +shift };
		if ( ref $library eq 'ARRAY' ) {
			require Type::Tiny::Union;
			return 'Type::Tiny::Union'->new(
				type_constraints => [ map $_->to_TypeTiny, @$library ],
			);
		}
		if ( $library ) {
			local $@;
			eval "require $library; 1" or die $@;
			my $type = $library->get_type( $origname );
			return $type if $type;
		}
		require Type::Tiny;
		return 'Type::Tiny'->new(
			name       => $name,
			constraint => sub { $coderef->( $_ ) },
			inlined    => sub { sprintf '%s::is_%s(%s)', $LIBRARY, $name, pop }
		);
	}

	sub DOES {
		return 1 if $_[1] eq 'Type::API::Constraint';
		return 1 if $_[1] eq 'Type::Library::Compiler::TypeConstraint';
		shift->DOES( @_ );
	}
};

# Int
{
	my $type;
	sub Int () {
		$type ||= bless( [ \&is_Int, "Int", "Types::Standard", "Int" ], "CompiledLib::TypeConstraint" );
	}

	sub is_Int ($) {
		(do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ })
	}

	sub assert_Int ($) {
		(do { my $tmp = $_[0]; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) ? $_[0] : Int->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Int"} = [ qw( Int is_Int assert_Int ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Int"} };
	push @{ $EXPORT_TAGS{"types"} },  "Int";
	push @{ $EXPORT_TAGS{"is"} },     "is_Int";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Int";

}

# Str
{
	my $type;
	sub Str () {
		$type ||= bless( [ \&is_Str, "Str", "Types::Standard", "Str" ], "CompiledLib::TypeConstraint" );
	}

	sub is_Str ($) {
		do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } }
	}

	sub assert_Str ($) {
		do {  defined($_[0]) and do { ref(\$_[0]) eq 'SCALAR' or ref(\(my $val = $_[0])) eq 'SCALAR' } } ? $_[0] : Str->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Str"} = [ qw( Str is_Str assert_Str ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Str"} };
	push @{ $EXPORT_TAGS{"types"} },  "Str";
	push @{ $EXPORT_TAGS{"is"} },     "is_Str";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Str";

}

# Undef
{
	my $type;
	sub Undef () {
		$type ||= bless( [ \&is_Undef, "Undef", "Types::Standard", "Undef" ], "CompiledLib::TypeConstraint" );
	}

	sub is_Undef ($) {
		(!defined($_[0]))
	}

	sub assert_Undef ($) {
		(!defined($_[0])) ? $_[0] : Undef->get_message( $_[0] );
	}

	$EXPORT_TAGS{"Undef"} = [ qw( Undef is_Undef assert_Undef ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"Undef"} };
	push @{ $EXPORT_TAGS{"types"} },  "Undef";
	push @{ $EXPORT_TAGS{"is"} },     "is_Undef";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_Undef";

}


1;
__END__

=head1 NAME

CompiledLib - type constraint library

=head1 TYPES

This type constraint library is even more basic that L<Type::Tiny>. Exported
types may be combined using C<< Foo | Bar >> but parameterized type constraints
like C<< Foo[Bar] >> are not supported.

=head2 B<Int>

Based on B<Int> in L<Types::Standard>.

The C<< Int >> constant returns a blessed type constraint object.
C<< is_Int($value) >> checks a value against the type and returns a boolean.
C<< assert_Int($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use CompiledLib qw( :Int );

=head2 B<Str>

Based on B<Str> in L<Types::Standard>.

The C<< Str >> constant returns a blessed type constraint object.
C<< is_Str($value) >> checks a value against the type and returns a boolean.
C<< assert_Str($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use CompiledLib qw( :Str );

=head2 B<Undef>

Based on B<Undef> in L<Types::Standard>.

The C<< Undef >> constant returns a blessed type constraint object.
C<< is_Undef($value) >> checks a value against the type and returns a boolean.
C<< assert_Undef($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use CompiledLib qw( :Undef );

=cut

