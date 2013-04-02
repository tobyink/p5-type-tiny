package Type::Tiny::Class;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::Class::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::Class::VERSION   = '0.000_02';
}

use Scalar::Util qw< blessed >;

sub _confess ($;@)
{
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::confess;
}

use base "Type::Tiny";

sub new {
	my $proto = shift;
	return $proto->class->new(@_) if blessed $proto; # DWIM
	
	my %opts = @_;
	_confess "need to supply class name" unless exists $opts{class};
	return $proto->SUPER::new(%opts);
}

sub class       { $_[0]{class} }
sub inlined     { $_[0]{inlined} ||= $_[0]->_build_inlined }

sub has_inlined { !!1 }

sub _build_constraint
{
	my $self  = shift;
	my $class = $self->class;
	return sub { blessed($_) and $_->isa($class) };
}

sub _build_inlined
{
	my $self  = shift;
	my $class = $self->class;
	my $var   = $_[0];
	return qq{blessed($var) and $var->isa(q[$class])};
}

sub _build_message
{
	my $self = shift;
	my $c = $self->class;
	return sub { sprintf 'value "%s" did not pass type constraint (not isa %s)', $_[0], $c } if $self->is_anon;
	my $name = "$self";
	return sub { sprintf 'value "%s" did not pass type constraint "%s" (not isa %s)', $_[0], $name, $c };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Tiny::Class - type constraints based on the "isa" method

=head1 DESCRIPTION

Type constraints of the general form C<< { $_->isa("Some::Class") } >>.

This package inherits from L<Type::Tiny>; see that for most documentation.
Major differences are listed below:

=head2 Attributes

=over

=item C<class>

The class for the constraint.

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

L<Moose::Meta::TypeConstraint::Class>.

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

