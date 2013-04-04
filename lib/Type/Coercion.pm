package Type::Coercion;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Coercion::AUTHORITY = 'cpan:TOBYINK';
	$Type::Coercion::VERSION   = '0.000_05';
}

use Scalar::Util qw< blessed >;
use Types::TypeTiny qw< CodeLike StringLike TypeTiny >;

sub _croak ($;@)
{
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::croak;
}

use overload
	q(&{})     => sub { my $t = shift; sub { $t->coerce(@_) } },
	q(bool)    => sub { !!1 },
	fallback   => 1,
;
use if ($] >= 5.010001), overload =>
	q(~~)      => sub { $_[0]->has_coercion_for_value($_[1]) },
;

sub new
{
	my $class  = shift;
	my %params = (@_==1) ? %{$_[0]} : @_;
	my $self   = bless \%params, $class;
	Scalar::Util::weaken($self->{type_constraint}); # break ref cycle
	return $self;
}

sub type_constraint     { $_[0]{type_constraint} }
sub type_coercion_map   { $_[0]{type_coercion_map} ||= [] }
sub moose_coercion      { $_[0]{moose_coercion}    ||= $_[0]->_build_moose_coercion }
sub compiled_coercion   { $_[0]{compiled_coercion} ||= $_[0]->_build_compiled_coercion }

sub has_type_constraint { defined $_[0]{type_constraint} } # sic

sub _clear_compiled_coercion { delete $_[0]{compiled_coercion} }

sub coerce
{
	my $self = shift;
	return $self->compiled_coercion->(@_);
}

sub assert_coerce
{
	my $self = shift;
	my $r = $self->coerce(@_);
	$self->type_constraint->assert_valid($r)
		if $self->has_type_constraint;
	return $r;
}

sub has_coercion_for_type
{
	my $self = shift;
	my $type = $_[0];
	
	for my $has (@{$self->type_coercion_map})
	{
		return !!1 if TypeTiny->check($has) && $type->is_a_type_of($has);
	}
	
	return;
}

sub has_coercion_for_value
{
	my $self = shift;
	my $c = $self->type_coercion_map;
	local $_ = $_[0];
	for (my $i = 0; $i <= $#$c; $i += 2)
	{
		return !!1 if $c->[$i]->check(@_);
	}
	return;
}

sub add_type_coercions
{
	my $self = shift;
	my @args = @_;
	
	while (@args)
	{
		my $type     = shift @args;
		my $coercion = shift @args;
		
		_croak "types must be blessed Type::Tiny objects"
			unless TypeTiny->check($type);
		_croak "coercions must be code references"
			unless StringLike->check($coercion) || CodeLike->check($coercion);
		
		push @{$self->type_coercion_map}, $type, $coercion;
	}
	
	$self->_clear_compiled_coercion;
	return $self;
}

sub _build_compiled_coercion
{
	my $self = shift;
	
	my @mishmash = @{$self->type_coercion_map};
	return sub { $_[0] } unless @mishmash;
	
	# These arrays will be closed over.
	my (@types, @codes);
	while (@mishmash)
	{
		push @types, shift @mishmash;
		push @codes, shift @mishmash;
	}
	if ($self->has_type_constraint)
	{
		unshift @types, $self->type_constraint;
		unshift @codes, undef;
	}
	
	my @sub;
	
	for my $i (0..$#types)
	{
		push @sub,
			$types[$i]->can_be_inlined ? sprintf('if (%s)', $types[$i]->inline_check('$_[0]')) :
			sprintf('if ($types[%d]->check(@_))', $i);
		push @sub,
			!defined($codes[$i])          ? sprintf('  { return $_[0] }') :
			StringLike->check($codes[$i]) ? sprintf('  { local $_ = $_[0]; return( %s ) }', $codes[$i]) :
			sprintf('  { local $_ = $_[0]; return $codes[%d]->(@_) }', $i);
	}
	
	push @sub, 'return $_[0];';
	
	local $@;
	my $sub = eval sprintf('sub ($) { %s }', join qq[\n], @sub);
	die "Failed to compile coercion: $@\n\nCODE: @sub" if $@;
	return $sub;
}

sub _build_moose_coercion
{
	my $self = shift;
	
	my %options = ();
	$options{type_coercion_map} = [ $self->_codelike_type_coercion_map('moose_type') ];
	$options{type_constraint}   = $self->type_constraint if $self->has_type_constraint;
	
	require Moose::Meta::TypeCoercion;
	my $r = "Moose::Meta::TypeCoercion"->new(%options);
	
	return $r;
}

sub _codelike_type_coercion_map
{
	my $self = shift;
	my $modifier = $_[0];
	
	my @orig = @{ $self->type_coercion_map };
	my @new;
	
	while (@orig)
	{
		my ($type, $converter) = splice(@orig, 0, 2);
		
		push @new, $modifier ? $type->$modifier : $type;
		
		if (CodeLike->check($converter))
		{
			push @new, $converter;
		}
		else
		{
			local $@;
			my $r = eval sprintf('sub { local $_ = $_[0]; %s }', $converter);
			die $@ if $@;
			push @new, $r;
		}
	}
	
	return @new;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Coercion - a set of coercions to a particular target type constraint

=head1 DESCRIPTION

=head2 Constructor

=over

=item C<< new(%attributes) >>

Moose-style constructor function.

=back

=head2 Attributes

=over

=item C<type_constraint>

Weak reference to the target type constraint (i.e. the type constraint which
the output of coercion coderefs is expected to conform to).

=item C<type_coercion_map>

Arrayref of source-type/code pairs. Don't set this in the constructor; use
the C<add_type_coercions> method instead.

=item C<< compiled_coercion >>

Coderef to coerce a value (C<< $_[0] >>).

The general point of this attribute is that you should not set it, and
rely on the lazily-built default. Type::Coerce will usually generate a
pretty fast coderef, inlining all type constraint checks, etc.

=item C<moose_coercion>

A L<Moose::Meta::TypeCoercion> object equivalent to this one. Don't set this
manually; rely on the default built one.

=back

=head2 Methods

=over

=item C<has_type_constraint>

Predicate method.

=item C<< add_type_coercions($type1, $code1, ...) >>

Takes one or more pairs of L<Type::Tiny> constraints and coercion code,
creating an ordered list of source types and coercion codes.

Coercion codes can be expressed as either a string of Perl code (this
includes objects which overload stringification), or a coderef (or object
that overloads coderefification). In either case, the value to be coerced
is C<< $_ >>.

=item C<< coerce($value) >>

Coerce the value to the target type.

=item C<< assert_coerce($value) >>

Coerce the value to the target type, and throw an exception if the result
does not validate against the target type constraint.

=item C<< has_coercion_for_type($source_type) >>

Not implemented yet.

=item C<< has_coercion_for_value($value) >>

Returns true iff the value could be coerced by this coercion.

=back

=head2 Overloading

=over

=item *

Boolification is overloaded to always return true.

=item *

Coderefification is overloaded to call C<coerce>.

=item *

On Perl 5.10.1 and above, smart match is overloaded to call C<has_coercion_for_value>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny::Manual>.

L<Type::Tiny>, L<Type::Library>, L<Type::Utils>, L<Types::Standard>.

L<Moose::Meta::TypeCoercion>.

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


