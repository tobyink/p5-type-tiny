package Test::TypeTiny;

use Test::More ();
use base "Exporter";

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_06';

our @EXPORT = qw( should_pass should_fail ok_subtype );

sub should_pass
{
	my ($value, $type) = @_;
	@_ = (
		!!$type->check($value),
		defined $value
			? sprintf("value '%s' passes type constraint '%s'", $value, $type)
			: sprintf("undef passes type constraint '%s'", $type),
	);
	goto \&Test::More::ok;
}

sub should_fail
{
	my ($value, $type) = @_;
	@_ = (
		!$type->check($value),
		defined $value
			? sprintf("value '%s' fails type constraint '%s'", $value, $type)
			: sprintf("undef fails type constraint '%s'", $type),
	);
	goto \&Test::More::ok;
}

sub ok_subtype
{
	my ($type, @s) = @_;
	@_ = (
		not(scalar grep !$_->is_subtype_of($type), @s),
		sprintf("%s subtype: %s", $type, join q[, ], @s),
	);
	goto \&Test::More::ok;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::TypeTiny - useful functions for testing the efficacy of type constraints

=head1 SYNOPSIS

   use strict;
   use warnings;
   use Test::More;
   use Test::TypeTiny;
   
   use Types::Mine qw(Integer);
   
   should_pass(1, Integer);
   should_pass(-1, Integer);
   should_pass(0, Integer);
   should_fail(2.5, Integer);
   
   ok_subtype(Number, Integer);
   
   done_testing;

=head1 DESCRIPTION

L<Test::TypeTiny> provides a couple of handy functions for testing type
constraints.

=head2 Functions

=over

=item C<< should_pass($value, $type) >>

=item C<< should_fail($value, $type) >>

=item C<< ok_subtype($type, @subtypes) >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny>.

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

