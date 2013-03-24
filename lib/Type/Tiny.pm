package Type::Tiny;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::VERSION   = '0.001';
}

use Scalar::Util qw< blessed >;

sub _confess ($;@) {
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::confess;
}

use overload
	q("")      => sub { $_[0]->name },
	q(bool)    => sub { 1 },
	q(&{})     => sub { my $t = shift; sub { $t->assert_valid(@_) } },
	fallback   => 1,
;

my @attributes = qw<
	name parent constraint coercion message inlined
>;

sub new
{
	my $class  = shift;
	my %params = (@_==1) ? %{$_[0]} : @_;
	my $self   = bless {} => $class;	
	exists($params{$_}) && $self->${\"_set_$_"}(delete $params{$_}) for @attributes; # self-documenting ;-)
	_confess 'unknown parameters (%s) passed to constructor for %s', join(q[, ], sort keys %params), $class if keys %params;
	$self->BUILD;
	return $self;
}

sub BUILD
{
	my $self = shift;
	
	my $name;
	defined($name = $self->name)
		? $self->_set_message(sub { sprintf 'value "%s" did not pass type constraint "%s"', $_[0], $name })
		: $self->_set_message(sub { sprintf 'value "%s" did not pass type constraint', $_[0] })
		unless $self->has_message;
}

sub _set_parent
{
	my $self = shift;
	my ($parent) = @_;
	_confess "parent must be an instance of %s", __PACKAGE__
		unless blessed($parent) && $parent->isa(__PACKAGE__);
	$self->{parent} = $parent;
}

for my $attr (@attributes)
{
	eval "sub $attr { \$_[0]{'$attr'} }"
		unless __PACKAGE__->can("$attr");
	eval "sub _set_$attr { \$_[0]{'$attr'} = \$_[1] }"
		unless __PACKAGE__->can("_set_$attr");
	eval "sub has_$attr { exists \$_[0]{'$attr'} }"
		unless __PACKAGE__->can("has_$attr");
	eval "sub _assert_$attr { return \$_[0]{'$attr'} if exists \$_[0]{'$attr'}; _confess '%s is not defined', '$attr'; }"
		unless __PACKAGE__->can("_assert_$attr");
}

sub check
{
	my $self = shift;
	return if $self->has_parent && !$self->parent->check($_[0]);
	local $_ = $_[0];
	return !!1 if $self->constraint->($_[0]);
	return;
}

sub validate
{
	my $self = shift;
	return undef if $self->check($_[0]);
	return $self->message->($_[0]);
}

sub assert_valid
{
	my $self = shift;
	return !!1 if $self->check($_[0]);
	_confess $self->message->($_[0]);
}

sub coerce
{
	...;
}

sub assert_coerce
{
	...;
}

sub as_moose
{	
	my $self = shift;
	
	my %options = (name => $self->name);
	$options{parent}     = $self->parent->as_moose if $self->has_parent;
	$options{constraint} = $self->constraint       if $self->has_constraint;
	$options{message}    = $self->message          if $self->has_message;
	# ... coerce
	
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

=head1 DESCRIPTION

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

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

