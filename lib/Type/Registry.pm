package Type::Registry;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Registry::AUTHORITY = 'cpan:TOBYINK';
	$Type::Registry::VERSION   = '0.005_04';
}

use Exporter::TypeTiny qw( mkopt _croak );
use Scalar::Util qw( refaddr );
use Types::TypeTiny qw( ArrayLike );

use base "Exporter::TypeTiny";
our @EXPORT_OK = qw(t);

sub _exporter_expand_sub
{
	my $class = shift;
	my ($name, $value, $globals, $permitted) = @_;
	
	if ($name eq "t")
	{
		my $caller = $globals->{into};
		my $reg = $class->for_class(
			ref($caller) ? sprintf('HASH(0x%08X)', refaddr($caller)) : $caller
		);
		return t => sub (;$) { @_ ? $reg->lookup(@_) : $reg };
	}
	
	return $class->SUPER::_exporter_expand_sub(@_);
}

sub new
{
	my $class = shift;
	ref($class) and _croak("not an object method");
	bless {}, $class;
}

{
	my %registries;
	
	sub for_class
	{
		my $class = shift;
		my ($for) = @_;
		$registries{$for} ||= $class->new;
	}
	
	sub for_me
	{
		my $class = shift;
		my $for   = caller;
		$registries{$for} ||= $class->new;
	}
}

sub add_types
{
	my $self = shift;
	my $opts = mkopt(\@_);
	for my $opt (@$opts)
	{
		my ($lib, $types) = @_;
		$types ||= [qw/-types/];
		
		$lib =~ s/^-/Types::/;
		eval "require $lib";
		$lib->isa("Type::Library") || $lib eq 'Types::TypeTiny'
			or _croak("%s is not a type library", $lib);
		
		ArrayLike->check($types)
			or _croak("Expected arrayref following '%s'; got %s", $lib, $types);
		
		my %hash;
		$lib->import({into => \%hash}, @$types);
		
		for my $key (sort keys %hash)
		{
			exists($self->{$key})
				and _croak("Duplicate type name: %s", $key);
			$self->{$key} = $hash{$key}->();
		}
	}
	$self;
}

sub alias_type
{
	my $self = shift;
	my ($old, @new) = @_;
	$self->{$_} = $self->{$old} for @new;
	$self;
}

# A bunch of stuff stolen from Moose::Util::TypeConstraints...
{
	no warnings;
	
	my $valid_chars = qr{[\w:\.]};
	my $type_atom   = qr{ (?>$valid_chars+) }x;
	my $ws          = qr{ (?>\s*) }x;
	my $op_union    = qr{ $ws \| $ws }x;
	my ($type, $type_capture_parts, $type_with_parameter, $union, $any);
	if ($] >= 5.010)
	{
		my $type_pattern    = q{  (?&type_atom)  (?: \[ (?&ws)  (?&any)  (?&ws) \] )? };
		my $type_capture_parts_pattern   = q{ ((?&type_atom)) (?: \[ (?&ws) ((?&any)) (?&ws) \] )? };
		my $type_with_parameter_pattern  = q{  (?&type_atom)      \[ (?&ws)  (?&any)  (?&ws) \]    };
		my $union_pattern   = q{ (?&type) (?> (?: (?&op_union) (?&type) )+ ) };
		my $any_pattern     = q{ (?&type) | (?&union) };
		
		my $defines = qr{(?(DEFINE)
			(?<valid_chars>         $valid_chars)
			(?<type_atom>           $type_atom)
			(?<ws>                  $ws)
			(?<op_union>            $op_union)
			(?<type>                $type_pattern)
			(?<type_capture_parts>  $type_capture_parts_pattern)
			(?<type_with_parameter> $type_with_parameter_pattern)
			(?<union>               $union_pattern)
			(?<any>                 $any_pattern)
		)}x;
		
		$type                = qr{ $type_pattern                $defines }x;
		$type_capture_parts  = qr{ $type_capture_parts_pattern  $defines }x;
		$type_with_parameter = qr{ $type_with_parameter_pattern $defines }x;
		$union               = qr{ $union_pattern               $defines }x;
		$any                 = qr{ $any_pattern                 $defines }x;
	}
	else
	{
		use re 'eval';
		
		$type                = qr{  $type_atom  (?: \[ $ws  (??{$any})  $ws \] )? }x;
		$type_capture_parts  = qr{ ($type_atom) (?: \[ $ws ((??{$any})) $ws \] )? }x;
		$type_with_parameter = qr{  $type_atom      \[ $ws  (??{$any})  $ws \]    }x;
		$union               = qr{ $type (?> (?: $op_union $type )+ ) }x;
		$any                 = qr{ $type | $union }x;
	}
	
	sub _parse_parameterized_type_constraint {
		{ no warnings 'void'; $any; }  # force capture of interpolated lexical
		my $self = shift;
		$_[0] =~ m{ $type_capture_parts }x;
		return ( $1, $2 );
	}
	
	sub _detect_parameterized_type_constraint {
		{ no warnings 'void'; $any; }  # force capture of interpolated lexical
		my $self = shift;
		$_[0] =~ m{ ^ $type_with_parameter $ }x;
	}
	
	sub _parse_type_constraint_union {
		{ no warnings 'void'; $any; }  # force capture of interpolated lexical
		my $self  = shift;
		my $given = shift;
		my @rv;
		while ( $given =~ m{ \G (?: $op_union )? ($type) }gcx ) {
			push @rv => $1;
		}
		( pos($given) eq length($given) )
		|| __PACKAGE__->_throw_error( "'$given' didn't parse (parse-pos="
			. pos($given)
			. " and str-length="
			. length($given)
			. ")" );
		@rv;
	}
	
	sub _detect_type_constraint_union {
		{ no warnings 'void'; $any; }  # force capture of interpolated lexical
		my $self = shift;
		$_[0] =~ m{^ $type $op_union $type ( $op_union .* )? $}x;
	}
	
	sub lookup
	{
		my $self = shift;
		
		my ($tc) = @_;
		$tc =~ s/(^\s+|\s+$)//g;
		
		if (exists $self->{$tc})
		{
			return $self->{$tc};
		}
		
		elsif ($self->_detect_type_constraint_union($tc))
		{
			require Type::Utils;
			my @tc = grep defined, map $self->lookup($_), $self->_parse_type_constraint_union($tc);
			return Type::Utils::union(\@tc);
		}
		
		elsif ($self->_detect_parameterized_type_constraint($tc))
		{
			my ($outer, @inner) = map $self->lookup($_)||$_, $self->_parse_parameterized_type_constraint($tc);
			return $outer->parameterize(@inner);
		}
		
		return;
	}
}

sub AUTOLOAD
{
	my $self = shift;
	my ($method) = (our $AUTOLOAD =~ /(\w+)$/);
	my $type = $self->lookup($method);
	return $type if $type;
	_croak(q[Can't locate object method "%s" via package "%s"], $method, ref($self));
}

1;

__END__

=pod

=encoding utf-8

=for stopwords optlist

=head1 NAME

Type::Registry - a glorified hashref for looking up type constraints

=head1 SYNOPSIS

   package Foo::Bar;
   
   use Type::Registry;
   
   my $reg = "Type::Registry"->for_me;  # a registry for Foo::Bar
   
   # Register all types from Types::Standard
   $reg->add_types(-Standard);
   
   # Register just one type from Types::XSD
   $reg->add_types(-XSD => ["NonNegativeInteger"]);
   
   # Register all types from MyApp::Types
   $reg->add_types("MyApp::Types");
   
   # Create a type alias
   $reg->alias_type("NonNegativeInteger" => "Count");
   
   # Look up a type constraint
   my $type = $reg->lookup("ArrayRef[Count]");
   
   $type->check([1, 2, 3.14159]);  # croaks

Alternatively:

   package Foo::Bar;
   
   use Type::Registry qw( t );
   
   # Register all types from Types::Standard
   t->add_types(-Standard);
   
   # Register just one type from Types::XSD
   t->add_types(-XSD => ["NonNegativeInteger"]);
   
   # Register all types from MyApp::Types
   t->add_types("MyApp::Types");
   
   # Create a type alias
   t->alias_type("NonNegativeInteger" => "Count");
   
   # Look up a type constraint
   my $type = t("ArrayRef[Count]");
   
   $type->check([1, 2, 3.14159]);  # croaks

=head1 DESCRIPTION

A type registry is basically just a hashref mapping type names to type
constraint objects.

=head2 Constructors

=over

=item C<< new >>

Create a new glorified hashref.

=item C<< for_class($class) >>

Create or return the existing glorified hashref associated with the given
class.

=item C<< for_me >>

Create or return the existing glorified hashref associated with the caller.

=back

=head2 Methods

=over

=item C<< add_types(@libraries) >>

The libraries list is treated as an "optlist" (a la L<Data::OptList>).

Strings are the names of type libraries; if the first character is a
hyphen, it is expanded to the "Types::" prefix. If followed by an
arrayref, this is the list of types to import from that library.
Otherwise

Strings are the names of type libraries; if the first character is a
hyphen, it is expanded to the "Types::" prefix. If followed by an
arrayref, this is the list of types to import from that library.
Otherwise, imports all types from the library.

	use Type::Registry qw(t);
	
	t->add_types(-Standard);  # OR: t->add_types("Types::Standard");
	
	t->add_types(
		-TypeTiny => ['HashLike'],
		-Standard => ['HashRef' => { -as => 'RealHash' }],
	);

=item C<< alias_type($oldname, $newname) >>

Create an alias for an existing type.

=item C<< lookup($name) >>

Look up a type in the registry by name. Supports a limited level of
DSL for unions and parameterized types.

	t->lookup("Int|ArrayRef[Int]")

Returns undef if not found.

=item C<< AUTOLOAD >>

Overloaded to call C<lookup>, but croaks if not found.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Library>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

