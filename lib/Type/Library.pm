package Type::Library;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Library::AUTHORITY = 'cpan:TOBYINK';
	$Type::Library::VERSION   = '1.999_005';
}

$Type::Library::VERSION =~ tr/_//d;

use Eval::TypeTiny qw< eval_closure set_subname type_to_coderef NICE_PROTOTYPES >;
use Scalar::Util qw< blessed refaddr >;
use Type::Tiny      ();
use Types::TypeTiny ();

require Exporter::Tiny;
our @ISA = 'Exporter::Tiny';

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

sub _exporter_validate_opts {
	my $class = shift;
	
	my $into = $_[0]{into};
	
	if ( $_[0]{base} || $_[0]{extends} and !ref $into ) {
		no strict "refs";
		push @{"$into\::ISA"}, $class;
		( my $file = $into ) =~ s{::}{/}g;
		$INC{"$file.pm"} ||= __FILE__;
	}
	
	if ( $_[0]{utils} ) {
		require Type::Utils;
		'Type::Utils'->import( { into => $into }, '-default' );
	}
	
	if ( $_[0]{extends} and !ref $into ) {
		require Type::Utils;
		my $wrapper = eval "sub { package $into; &Type::Utils::extends; }";
		my @libs    = @{
			ref( $_[0]{extends} )
			? $_[0]{extends}
			: ( $_[0]{extends} ? [ $_[0]{extends} ] : [] )
		};
		$wrapper->( @libs );
	} #/ if ( $_[0]{extends} and...)
	
	return $class->SUPER::_exporter_validate_opts( @_ );
} #/ sub _exporter_validate_opts

sub _exporter_expand_sub {
	my $class = shift;
	my ( $name, $value, $globals ) = @_;
	
	if ( $name =~ /^\+(.+)/ and $class->has_type( "$1" ) ) {
		my $type     = $class->get_type( "$1" );
		my $value2   = +{ %{ $value || {} } };
		my $exported = $type->exportables;
		return map $class->_exporter_expand_sub( $_->{name}, $value2, $globals ), @$exported;
	}
	
	my $typename = $name;
	my $thingy   = undef;
	if ( $name =~ /^(is|assert|to)_(.+)$/ ) {
		$thingy   = $1;
		$typename = $2;
	}
	
	if ( my $type = $class->get_type( $typename ) ) {
		my $custom_type = 0;
		for my $param ( qw/ of where / ) {
			exists $value->{$param} or next;
			defined $value->{-as}
				or _croak( "Parameter '-as' not supplied" );
			$type = $type->$param( $value->{$param} );
			$name = $value->{-as};
			++$custom_type;
		}
		
		if ( not defined $thingy ) {
			my $post_method = q();
			$post_method = '->mouse_type' if $globals->{mouse};
			$post_method = '->moose_type' if $globals->{moose};
			return ( $name => type_to_coderef( $type, post_method => $post_method ) )
				if $post_method || $custom_type;
		}
		elsif ( $custom_type ) {
			for my $exportable ( @{ $type->exportables( $typename ) } ) {
				for my $tag ( @{ $exportable->{tags} } ) {
					if ( $thingy eq $tag ) {
						return ( $value->{-as} || $exportable->{name}, $exportable->{code} );
					}
				}
			}
		}
	} #/ if ( my $type = $class...)
	
	return $class->SUPER::_exporter_expand_sub( @_ );
} #/ sub _exporter_expand_sub

sub _exporter_install_sub {
	my $class = shift;
	my ( $name, $value, $globals, $sym ) = @_;
	
	my $package = $globals->{into};
	my $type    = $class->get_type( $name );
	
	Exporter::Tiny::_carp(
		"Exporting deprecated type %s to %s",
		$type->qualified_name,
		ref( $package ) ? "reference" : "package $package",
	) if ( defined $type and $type->deprecated and not $globals->{allow_deprecated} );
	
	if ( !ref $package and defined $type ) {
		my ( $prefix ) = grep defined, $value->{-prefix}, $globals->{prefix}, q();
		my ( $suffix ) = grep defined, $value->{-suffix}, $globals->{suffix}, q();
		my $as         = $prefix . ( $value->{-as} || $name ) . $suffix;
		
		$INC{'Type/Registry.pm'}
			? 'Type::Registry'->for_class( $package )->add_type( $type, $as )
			: ( $Type::Registry::DELAYED{$package}{$as} = $type );
	}
	
	$class->SUPER::_exporter_install_sub( @_ );
} #/ sub _exporter_install_sub

sub _exporter_fail {
	my $class = shift;
	my ( $name, $value, $globals ) = @_;
	
	my $into = $globals->{into}
		or _croak( "Parameter 'into' not supplied" );
		
	if ( $globals->{declare} ) {
		my $declared = sub (;$) {
			my $params;
			$params = shift if ref( $_[0] ) eq "ARRAY";
			my $type = $into->get_type( $name );
			my $t;
			
			if ( $type ) {
				$t = $params ? $type->parameterize( @$params ) : $type;
			}
			else {
				_croak "Cannot parameterize a non-existant type" if $params;
				$t = Type::Tiny::_DeclaredType->new( library => $into, name => $name );
			}
			
			@_ && wantarray ? return ( $t, @_ ) : return $t;
		};
		
		return (
			$name,
			set_subname(
				"$class\::$name",
				NICE_PROTOTYPES ? sub (;$) { goto $declared } : sub (;@) { goto $declared },
			),
		);
	} #/ if ( $globals->{declare...})
	
	return $class->SUPER::_exporter_fail( @_ );
} #/ sub _exporter_fail

{

	package Type::Tiny::_DeclaredType;
	our @ISA = 'Type::Tiny';
	
	sub new {
		my $class   = shift;
		my %opts    = @_ == 1 ? %{ +shift } : @_;
		my $library = delete $opts{library};
		my $name    = delete $opts{name};
		$opts{display_name} = $name;
		$opts{constraint}   = sub {
			my $val = @_ ? pop : $_;
			$library->get_type( $name )->check( $val );
		};
		$opts{inlined} = sub {
			my $val = @_ ? pop : $_;
			sprintf( '%s::is_%s(%s)', $library, $name, $val );
		};
		$opts{_build_coercion} = sub {
			my $realtype = $library->get_type( $name );
			$_[0] = $realtype->coercion if $realtype;
		};
		$class->SUPER::new( %opts );
	} #/ sub new
}

sub meta {
	no strict "refs";
	no warnings "once";
	return $_[0] if blessed $_[0];
	${"$_[0]\::META"} ||= bless {}, $_[0];
}

sub add_type {
	my $meta  = shift->meta;
	my $class = blessed( $meta );
	
	my $type =
		ref( $_[0] ) =~ /^Type::Tiny\b/ ? $_[0]
		: blessed( $_[0] )              ? Types::TypeTiny::to_TypeTiny( $_[0] )
		: ref( $_[0] ) eq q(HASH)
		? 'Type::Tiny'->new( library => $class, %{ $_[0] } )
		: "Type::Tiny"->new( library => $class, @_ );
	my $name = $type->{name};
	
	$meta->{types} ||= {};
	_croak 'Type %s already exists in this library', $name
		if $meta->has_type( $name );
	_croak 'Type %s conflicts with coercion of same name', $name
		if $meta->has_coercion( $name );
	_croak 'Cannot add anonymous type to a library' if $type->is_anon;
	$meta->{types}{$name} = $type;
	
	no strict "refs";
	no warnings "redefine", "prototype";
	
	for my $exportable ( @{ $type->exportables } ) {
		my $name = $exportable->{name};
		my $code = $exportable->{code};
		my $tags = $exportable->{tags};
		*{"$class\::$name"} = set_subname( "$class\::$name", $code );
		push @{"$class\::EXPORT_OK"}, $name;
		push @{ ${"$class\::EXPORT_TAGS"}{$_} ||= [] }, $name for @$tags;
	}
	
	return $type;
} #/ sub add_type

sub get_type {
	my $meta = shift->meta;
	$meta->{types}{ $_[0] };
}

sub has_type {
	my $meta = shift->meta;
	exists $meta->{types}{ $_[0] };
}

sub type_names {
	my $meta = shift->meta;
	keys %{ $meta->{types} };
}

sub add_coercion {
	require Type::Coercion;
	my $meta = shift->meta;
	my $c    = blessed( $_[0] ) ? $_[0] : "Type::Coercion"->new( @_ );
	my $name = $c->name;
	
	$meta->{coercions} ||= {};
	_croak 'Coercion %s already exists in this library', $name
		if $meta->has_coercion( $name );
	_croak 'Coercion %s conflicts with type of same name', $name
		if $meta->has_type( $name );
	_croak 'Cannot add anonymous type to a library' if $c->is_anon;
	$meta->{coercions}{$name} = $c;
	
	no strict "refs";
	no warnings "redefine", "prototype";
	
	my $class = blessed( $meta );
	*{"$class\::$name"} = type_to_coderef( $c );
	
	push @{"$class\::EXPORT_OK"}, $name;
	push @{ ${"$class\::EXPORT_TAGS"}{'coercions'} ||= [] }, $name;

	return $c;
} #/ sub add_coercion

sub get_coercion {
	my $meta = shift->meta;
	$meta->{coercions}{ $_[0] };
}

sub has_coercion {
	my $meta = shift->meta;
	exists $meta->{coercions}{ $_[0] };
}

sub coercion_names {
	my $meta = shift->meta;
	keys %{ $meta->{coercions} };
}

sub make_immutable {
	my $meta  = shift->meta;
	my $class = ref( $meta );
	
	no strict "refs";
	no warnings "redefine", "prototype";
	
	for my $type ( values %{ $meta->{types} } ) {
		$type->coercion->freeze;
		my $name = $type->name;
		*{"$class\::to_$name"} = set_subname(
			"$class\::to_$name",
			$type->coercion->compiled_coercion,
		) if $type->has_coercion && $type->coercion->frozen;
	} #/ for my $type ( values %...)
	
	1;
} #/ sub make_immutable

1;

__END__

=pod

=encoding utf-8

=for stopwords Moo(se)-compatible MooseX::Types-like

=head1 NAME

Type::Library - tiny, yet Moo(se)-compatible type libraries

=head1 SYNOPSIS

=for test_synopsis
BEGIN { die "SKIP: crams multiple modules into single example" };

   package Types::Mine {
      use Scalar::Util qw(looks_like_number);
      use Type::Library -base;
      use Type::Tiny;
      
      my $NUM = "Type::Tiny"->new(
         name       => "Number",
         constraint => sub { looks_like_number($_) },
         message    => sub { "$_ ain't a number" },
      );
      
      __PACKAGE__->meta->add_type($NUM);
      
      __PACKAGE__->meta->make_immutable;
   }
      
   package Ermintrude {
      use Moo;
      use Types::Mine qw(Number);
      has favourite_number => (is => "ro", isa => Number);
   }
   
   package Bullwinkle {
      use Moose;
      use Types::Mine qw(Number);
      has favourite_number => (is => "ro", isa => Number);
   }
   
   package Maisy {
      use Mouse;
      use Types::Mine qw(Number);
      has favourite_number => (is => "ro", isa => Number);
   }

=head1 STATUS

This module is covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

L<Type::Library> is a tiny class for creating MooseX::Types-like type
libraries which are compatible with Moo, Moose and Mouse.

If you're reading this because you want to create a type library, then
you're probably better off reading L<Type::Tiny::Manual::Libraries>.

=head2 Methods

A type library is a singleton class. Use the C<meta> method to get a blessed
object which other methods can get called on. For example:

   Types::Mine->meta->add_type($foo);

=begin trustme

=item meta

=end trustme

=over

=item C<< add_type($type) >> or C<< add_type(%opts) >>

Add a type to the library. If C<< %opts >> is given, then this method calls
C<< Type::Tiny->new(%opts) >> first, and adds the resultant type.

Adding a type named "Foo" to the library will automatically define four
functions in the library's namespace:

=over

=item C<< Foo >>

Returns the Type::Tiny object.

=item C<< is_Foo($value) >>

Returns true iff $value passes the type constraint.

=item C<< assert_Foo($value) >>

Returns $value iff $value passes the type constraint. Dies otherwise.

=item C<< to_Foo($value) >>

Coerces the value to the type.

=back

=item C<< get_type($name) >>

Gets the C<Type::Tiny> object corresponding to the name.

=item C<< has_type($name) >>

Boolean; returns true if the type exists in the library.

=item C<< type_names >>

List all types defined by the library.

=item C<< add_coercion($c) >> or C<< add_coercion(%opts) >>

Add a standalone coercion to the library. If C<< %opts >> is given, then
this method calls C<< Type::Coercion->new(%opts) >> first, and adds the
resultant coercion.

Adding a coercion named "FooFromBar" to the library will automatically
define a function in the library's namespace:

=over

=item C<< FooFromBar >>

Returns the Type::Coercion object.

=back

=item C<< get_coercion($name) >>

Gets the C<Type::Coercion> object corresponding to the name.

=item C<< has_coercion($name) >>

Boolean; returns true if the coercion exists in the library.

=item C<< coercion_names >>

List all standalone coercions defined by the library.

=item C<< import(@args) >>

Type::Library-based libraries are exporters.

=item C<< make_immutable >>

A shortcut for calling C<< $type->coercion->freeze >> on every
type constraint in the library.

=back

=head2 Export

Type libraries are exporters. For the purposes of the following examples,
assume that the C<Types::Mine> library defines types C<Number> and C<String>.

   # Exports nothing.
   # 
   use Types::Mine;
   
   # Exports a function "String" which is a constant returning
   # the String type constraint.
   #
   use Types::Mine qw( String );
   
   # Exports both String and Number as above.
   #
   use Types::Mine qw( String Number );
   
   # Same.
   #
   use Types::Mine qw( :types );
   
   # Exports "coerce_String" and "coerce_Number", as well as any other
   # coercions
   #
   use Types::Mine qw( :coercions );
   
   # Exports a sub "is_String" so that "is_String($foo)" is equivalent
   # to "String->check($foo)".
   #
   use Types::Mine qw( is_String );
   
   # Exports "is_String" and "is_Number".
   #
   use Types::Mine qw( :is );
   
   # Exports a sub "assert_String" so that "assert_String($foo)" is
   # equivalent to "String->assert_return($foo)".
   #
   use Types::Mine qw( assert_String );
   
   # Exports "assert_String" and "assert_Number".
   #
   use Types::Mine qw( :assert );
   
   # Exports a sub "to_String" so that "to_String($foo)" is equivalent
   # to "String->coerce($foo)".
   #
   use Types::Mine qw( to_String );
   
   # Exports "to_String" and "to_Number".
   #
   use Types::Mine qw( :to );
   
   # Exports "String", "is_String", "assert_String" and "coerce_String".
   #
   use Types::Mine qw( +String );
   
   # Exports everything.
   #
   use Types::Mine qw( :all );

Type libraries automatically inherit from L<Exporter::Tiny>; see the
documentation of that module for tips and tricks importing from libraries.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-type-tiny/issues>.

=head1 SEE ALSO

L<Type::Tiny::Manual>.

L<Type::Tiny>, L<Type::Utils>, L<Types::Standard>, L<Type::Coercion>.

L<Moose::Util::TypeConstraints>,
L<Mouse::Util::TypeConstraints>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
