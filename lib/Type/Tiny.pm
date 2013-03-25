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
	q("")      => sub { $_[0]->name },
	q(bool)    => sub { 1 },
	q(&{})     => sub { my $t = shift; sub { $t->assert_valid(@_) } },
	fallback   => 1,
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
		
	bless \%params, $class;
}

sub name        { $_[0]{name} }
sub parent      { $_[0]{parent} }
sub constraint  { $_[0]{constraint} ||= $_[0]->_build_constraint }
sub coercion    { $_[0]{coercion} }
sub message     { $_[0]{message}    ||= $_[0]->_build_message }
sub inlined     { $_[0]{coercion} }
sub has_parent  { exists $_[0]{parent} }
sub has_inlined { exists $_[0]{inlined} }

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

sub is_anon
{
	my $self = shift;
	$self->name eq "__ANON__";
}

sub _get_failure_level
{
	my $self = shift;
	
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
	return if $self->has_parent && !$self->parent->check($_[0]);
	return if $self->_get_failure_level;
	return !!1;
}

sub validate
{
	my $self = shift;
	
	my $failed_at = $self->_get_failure_level($_[0]);
	return undef unless defined $failed_at;
	
	local $_ = $_[0];
	return $failed_at->message->($_[0]);
}

sub assert_valid
{
	my $self = shift;
	
	my $failed_at = $self->_get_failure_level($_[0]);
	return !!1 unless defined $failed_at;
	
	local $_ = $_[0];
	_confess $failed_at->message->($_[0]);
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

