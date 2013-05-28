package Type::Tiny::Role;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::Role::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::Role::VERSION   = '0.006';
}

use Scalar::Util qw< blessed >;

sub _croak ($;@) { require Type::Exception; goto \&Type::Exception::croak }

use base "Type::Tiny";

sub new {
	my $proto = shift;
	my %opts = @_;
	_croak "Role type constraints cannot have a parent constraint" if exists $opts{parent};
	_croak "Need to supply role name" unless exists $opts{role};
	return $proto->SUPER::new(%opts);
}

sub role        { $_[0]{role} }
sub inlined     { $_[0]{inlined} ||= $_[0]->_build_inlined }

sub has_inlined { !!1 }

sub _build_constraint
{
	my $self = shift;
	my $role = $self->role;
	return sub { blessed($_) and do { my $method = $_->can('DOES')||$_->can('isa'); $_->$method($role) } };
}

sub _build_inlined
{
	my $self = shift;
	my $role = $self->role;
	sub {
		my $var = $_[1];
		qq{Scalar::Util::blessed($var) and do { my \$method = $var->can('DOES')||$var->can('isa'); $var->\$method(q[$role]) }};
	};
}

sub _build_default_message
{
	my $self = shift;
	my $c = $self->role;
	return sub { sprintf 'value "%s" did not pass type constraint (not DOES %s)', $_[0], $c } if $self->is_anon;
	my $name = "$self";
	return sub { sprintf 'value "%s" did not pass type constraint "%s" (not DOES %s)', $_[0], $name, $c };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Tiny::Role - type constraints based on the "DOES" method

=head1 DESCRIPTION

Type constraints of the general form C<< { $_->DOES("Some::Role") } >>.

This package inherits from L<Type::Tiny>; see that for most documentation.
Major differences are listed below:

=head2 Attributes

=over

=item C<role>

The role for the constraint.

Note that this package doesn't subscribe to any particular flavour of roles
(L<Moose::Role>, L<Mouse::Role>, L<Moo::Role>, L<Role::Tiny>, etc). It simply
trusts the object's C<DOES> method (see L<UNIVERSAL>).

=item C<constraint>

Unlike Type::Tiny, you should generally I<not> pass a constraint to the
constructor. Instead rely on the default.

=item C<inlined>

Unlike Type::Tiny, you should generally I<not> pass an inlining coderef to
the constructor. Instead rely on the default.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny::Manual>.

L<Type::Tiny>.

L<Moose::Meta::TypeConstraint::Role>.

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

