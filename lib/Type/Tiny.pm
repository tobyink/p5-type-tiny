package Type::Tiny;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::VERSION   = '0.001';
}

use Scalar::Util qw< blessed >;

sub _confess ($;@)
{
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::confess;
}

use overload
	q("")      => sub { $_[0]->qualified_name },
	q(bool)    => sub { 1 },
	q(&{})     => sub { my $t = shift; sub { $t->assert_valid(@_) } },
	fallback   => 1,
;
use if ($] >= 5.010001), overload =>
	q(~~)      => sub { $_[0]->check($_[1]) },
;

sub new
{
	my $class  = shift;
	my %params = (@_==1) ? %{$_[0]} : @_;
	
	if (exists $params{parent})
	{
		_confess "parent must be an instance of %s", __PACKAGE__
			unless blessed($params{parent}) && $params{parent}->isa(__PACKAGE__);
	}
	
	$params{name} = "__ANON__" unless exists $params{name};
	
	my $self = bless \%params, $class;
	
	if ($self->has_library and not $self->is_anon)
	{
		$Moo::HandleMoose::TYPE_MAP{"$self"} = sub { $self->as_moose };
	}
	
	return $self;
}

sub name        { $_[0]{name} }
sub parent      { $_[0]{parent} }
sub constraint  { $_[0]{constraint} ||= $_[0]->_build_constraint }
sub coercion    { $_[0]{coercion} }
sub message     { $_[0]{message}    ||= $_[0]->_build_message }
sub inlined     { $_[0]{inlined} }
sub library     { $_[0]{library} }

sub has_parent   { exists $_[0]{parent} }
sub has_inlined  { exists $_[0]{inlined} }
sub has_library  { exists $_[0]{library} }
sub has_coercion { exists $_[0]{coercion} }

sub _assert_coercion
{
	my $self = shift;
	$self->has_coercion or _confess "no coercion for this type constraint";
	return $self->coercion;
}

sub _build_constraint
{
	return sub { !!1 };
}

sub _build_message
{
	my $self = shift;
	return sub { sprintf 'value "%s" did not pass type constraint', $_[0] } if $self->is_anon;
	my $name = "$self";
	return sub { sprintf 'value "%s" did not pass type constraint "%s"', $_[0], $name };
}

sub qualified_name
{
	my $self = shift;
	
	if ($self->has_library and not $self->is_anon)
	{
		return sprintf("%s::%s", $self->library, $self->name);
	}
	
	return $self->name;
}

sub is_anon
{
	my $self = shift;
	$self->name eq "__ANON__";
}

sub parents
{
	my $self = shift;
	return unless $self->has_parent;
	return ($self->parent, $self->parent->parents);
}

sub _get_failure_level
{
	my $self = shift;
	_confess "need an argument!" unless @_;
	
	if ($self->has_parent)
	{
		my $failed_at = $self->parent->_get_failure_level(@_);
		return $failed_at if defined $failed_at;
	}
	
	local $_ = $_[0];
	return if $self->constraint->($_[0]);
	return $self;
}

sub check
{
	my $self = shift;
	return !$self->_get_failure_level(@_);
}

sub get_message
{
	my $self = shift;
	$self->message->(@_);
}

sub validate
{
	my $self = shift;
	
	my $failed_at = $self->_get_failure_level($_[0]);
	return undef unless defined $failed_at;
	
	local $_ = $_[0];
	return $failed_at->get_message($_[0]);
}

sub assert_valid
{
	my $self = shift;
	
	my $failed_at = $self->_get_failure_level($_[0]);
	return !!1 unless defined $failed_at;
	
	local $_ = $_[0];
	_confess $failed_at->get_message($_[0]);
}

sub coerce
{
	my $self = shift;
	$self->_assert_coercion->coerce(@_);
}

sub assert_coerce
{
	my $self = shift;
	$self->_assert_coercion->assert_coerce(@_);
}

sub as_moose
{	
	my $self = shift;
	
	my %options = (name => $self->qualified_name);
	$options{parent}     = $self->parent->as_moose if $self->has_parent;
	$options{constraint} = $self->constraint;
	$options{message}    = $self->message;
	# XXX - ... coercion
	
	require Moose::Meta::TypeConstraint;
	return "Moose::Meta::TypeConstraint"->new(%options);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Tiny - tiny, yet Moo(se)-compatible type constraint

=head1 SYNOPSIS

	use Scalar::Util qw(looks_like_number);
	use Type::Tiny;
	
	my $NUM = "Type::Tiny"->new(
		name       => "Number",
		constraint => sub { looks_like_number($_) },
		message    => sub { "$_ ain't a number" },
	);
	
	package Ermintrude {
		use Moo;
		has favourite_number => (is => "ro", isa => $NUM);
	}
	
	package Bullwinkle {
		use Moose;
		has favourite_number => (is => "ro", isa => $NUM->as_moose);
	}

=head1 DESCRIPTION

L<Type::Tiny> is a tiny class for creating Moose-like type constraint
objects which are compatible with Moo and Moose.

Maybe now we won't need to have separate MooseX and MooX versions of
everything? We can but hope...

If you're reading this because you want to create a type library, then
you're probably better off reading L<Type::Tiny::Intro>.

=head2 Constructor

=over

=item C<< new(%attributes) >>

Moose-style constructor function.

=back

=head2 Attributes

=over

=item C<< name >>

The name of the type constraint.

=item C<< parent >>

Optional attribute; parent type constraint. For example, an "Integer"
type constraint might have a parent "Number".

If provided, must be a Type::Tiny object.

=item C<< constraint >>

Coderef to validate a value (C<< $_ >>) against the type constraint. The
coderef will not be called unless the value is known to pass any parent
type constraint. Defaults to C<< sub { 1 } >> - i.e. a coderef that passes
all values.

=item C<< coercion >>

(Not implemented yet.)

=item C<< message >>

Coderef that returns an error message when C<< $_ >> does not validate
against the type constraint. Optional (there's a vaguely sensible default.)

=item C<< inlined >>

(Not implemented yet.)

=item C<< library >>

The package name of the type library this type is associated with.
Optional. Informational only: setting this attribute does not install
the type into the package.

=back

=head2 Methods

=over

=item C<< has_parent >>, C<< has_inlined >>, C<< has_library >>

Predicate methods.

=item C<< is_anon >>

Returns true iff the type constraint does not have a name.

=item C<< qualified_name >>

For non-anonymous type constraints that have a library, returns a qualified
C<< "Library::Type" >> sort of name. Otherwise, returns the same as
C<< name >>.

=item C<< parents >>

Returns a list of all this type constraint's all ancestor constraints.

=item C<< check($value) >>

Returns true iff the value passes the type constraint.

=item C<< validate($value) >>

Returns the error message for the value; returns an explicit undef if the
value passes the type constraint.

=item C<< assert_valid($value) >>

Like C<< check($value) >> but dies if the value does not pass the type
constraint.

Yes, that's three very similar methods. Blame L<Moose::Meta::TypeConstraint>
whose API I'm attempting to emulate. :-)

=item C<< get_message($value) >>

Returns the error message for the value; even if the value passes the type
constraint.

=item C<< coerce($value) >>

Not implemented yet.

=item C<< assert_coerce($value) >>

Not implemented yet.

=item C<< as_moose >>

Returns a L<Moose::Meta::TypeConstraint> object equivalent to this Type::Tiny
object.

=back

=head2 Overloading

=over

=item *

Stringification is overloaded to return the qualified name.

=item *

Boolification is overloaded to always return true.

=item *

Coderefification is overloaded to call C<assert_value>.

=item *

On Perl 5.10.1 and above, smart match is overloaded to call C<check>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny::Intro>, L<Type::Library>, L<Type::Library::Util>.

L<Moose::Meta::TypeConstraint>.

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

