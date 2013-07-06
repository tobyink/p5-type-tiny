package Type::Tiny::Enum;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::Enum::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::Enum::VERSION   = '0.015_02';
}

sub _croak ($;@) { require Type::Exception; goto \&Type::Exception::croak }

use overload q[@{}] => 'values';

use base "Type::Tiny";

sub new
{
	my $proto = shift;
	
	my %opts = @_;
	_croak "Enum type constraints cannot have a parent constraint passed to the constructor" if exists $opts{parent};
	_croak "Enum type constraints cannot have a constraint coderef passed to the constructor" if exists $opts{constraint};
	_croak "Enum type constraints cannot have a inlining coderef passed to the constructor" if exists $opts{inlined};
	_croak "Need to supply list of values" unless exists $opts{values};
	
	my %tmp =
		map { $_ => 1 }
		@{ ref $opts{values} eq "ARRAY" ? $opts{values} : [$opts{values}] };
	$opts{values} = [sort keys %tmp];
	
	return $proto->SUPER::new(%opts);
}

sub values      { $_[0]{values} }
sub constraint  { $_[0]{constraint} ||= $_[0]->_build_constraint }

sub _build_display_name
{
	my $self = shift;
	sprintf("Enum[%s]", join q[,], @$self);
}

sub _build_constraint
{
	my $self = shift;
	my $regexp = join "|", map quotemeta, @$self;
	return sub { defined and m{^(?:$regexp)$} };
}

sub can_be_inlined
{
	!!1;
}

sub inline_check
{
	my $self = shift;
	my $regexp = join "|", map quotemeta, @$self;
	$_[0] eq '$_'
		? "(defined and m{^(?:$regexp)\$})"
		: "(defined($_[0]) and $_[0] =~ m{^(?:$regexp)\$})";
}

sub _instantiate_moose_type
{
	my $self = shift;
	my %opts = @_;
	delete $opts{parent};
	delete $opts{constraint};
	delete $opts{inlined};
	require Moose::Meta::TypeConstraint::Enum;
	return "Moose::Meta::TypeConstraint::Enum"->new(%opts, values => $self->values);
}

sub has_parent
{
	!!1;
}

sub parent
{
	require Types::Standard;
	Types::Standard::Str();
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Tiny::Enum - string enum type constraints

=head1 DESCRIPTION

Enum type constraints.

This package inherits from L<Type::Tiny>; see that for most documentation.
Major differences are listed below:

=head2 Attributes

=over

=item C<values>

Arrayref of allowable value strings. Non-string values (e.g. objects with
overloading) will be stringified in the constructor.

=item C<constraint>

Unlike Type::Tiny, you should generally I<not> pass a constraint to the
constructor. Instead rely on the default.

=item C<inlined>

Unlike Type::Tiny, you should generally I<not> pass an inlining coderef to
the constructor. Instead rely on the default.

=item C<parent>

Parent is always Types::Standard::Str, and cannot be passed to the
constructor.

=back

=head2 Overloading

=over

=item *

Arrayrefification calls C<values>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny::Manual>.

L<Type::Tiny>.

L<Moose::Meta::TypeConstraint::Enum>.

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

