package Type::Coercion;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Coercion::AUTHORITY = 'cpan:TOBYINK';
	$Type::Coercion::VERSION   = '0.001';
}

use Scalar::Util qw< blessed >;

sub _confess ($;@)
{
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::confess;
}

use overload
	q(&{})     => sub { my $t = shift; sub { $t->coerce(@_) } },
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

sub has_type_constraint { exists $_[0]{type_constraint} }

sub coerce
{
	my $self = shift;
	my $c = $self->type_coercion_map;
	local $_ = $_[0];
	for (my $i = 0; $i <= $#$c; $i += 2)
	{
		return scalar $c->[$i+1]->(@_) if $c->[$i]->check(@_);
	}
	return $_[0];
}

sub assert_coerce
{
	my $self = shift;
	my $r = $self->coerce(@_);
	if ($self->has_type_constraint)
	{
		$self->type_constraint->assert_valid($r);
	}
	return $r;
}

sub has_coercion_for_type
{
	die "not implemented";
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
		
		_confess "types must be blessed Type::Tiny objects"
			unless blessed($type) && $type->isa("Type::Tiny");
		_confess "coercions must be code references"
			unless ref($coercion);  # really want: does($coercion, "&{}")
		
		push @{$self->type_coercion_map}, $type, $coercion;
	}
	
	return $self;
}

sub _build_moose_coercion
{
	my $self = shift;
	
	my %options = ();
	$options{type_coercion_map} = [
		map { blessed($_) && $_->can("moose_type") ? $_->moose_type : $_ }
		@{ $self->type_coercion_map }
	];
	$options{type_constraint} = $self->type_constraint if $self->has_type_constraint;
	
	require Moose::Meta::TypeCoercion;
	my $r = "Moose::Meta::TypeCoercion"->new(%options);
	
	return $r;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Coercion - a set of coercions to a particular target type constraint

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny::Manual>.

L<Type::Tiny>, L<Type::Library>, L<Type::Utils>, L<Type::Standard>.

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


