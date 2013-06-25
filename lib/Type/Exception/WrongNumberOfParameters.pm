package Type::Exception::WrongNumberOfParameters;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Exception::WrongNumberOfParameters::AUTHORITY = 'cpan:TOBYINK';
	$Type::Exception::WrongNumberOfParameters::VERSION   = '0.011_02';
}

use base "Type::Exception";

sub minimum    { $_[0]{minimum} };
sub maximum    { $_[0]{maximum} };
sub got        { $_[0]{got} };

sub has_minimum { exists $_[0]{minimum} };
sub has_maximum { exists $_[0]{maximum} };

sub _build_message
{
	my $e = shift;
	if ($e->has_minimum and $e->has_maximum and $e->minimum == $e->maximum)
	{
		return sprintf(
			"Wrong number of parameters; got %d; expected %d",
			$e->got,
			$e->minimum,
		);
	}
	elsif ($e->has_minimum and $e->has_maximum and $e->minimum < $e->maximum)
	{
		return sprintf(
			"Wrong number of parameters; got %d; expected %d to %d",
			$e->got,
			$e->minimum,
			$e->maximum,
		);
	}
	elsif ($e->has_minimum)
	{
		return sprintf(
			"Wrong number of parameters; got %d; expected at least %d",
			$e->got,
			$e->minimum,
		);
	}
	else
	{
		return sprintf(
			"Wrong number of parameters; got %d",
			$e->got,
		);
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Exception::WrongNumberOfParameters - exception for Type::Params

=head1 DESCRIPTION

Thrown when a Type::Params compiled check is called with the wrong number
of parameters.

This package inherits from L<Type::Exception>; see that for most
documentation. Major differences are listed below:

=head2 Attributes

=over

=item C<minimum>

The minimum expected number of parameters.

=item C<maximum>

The maximum expected number of parameters.

=item C<got>

The number of parameters actually passed to the compiled check.

=back

=head2 Methods

=over

=item C<has_minimum>, C<has_maximum>

Predicate methods.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Exception>.

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

