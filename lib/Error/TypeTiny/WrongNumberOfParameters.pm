package Error::TypeTiny::WrongNumberOfParameters;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Error::TypeTiny::WrongNumberOfParameters::AUTHORITY = 'cpan:TOBYINK';
	$Error::TypeTiny::WrongNumberOfParameters::VERSION   = '2.008005';
}

$Error::TypeTiny::WrongNumberOfParameters::VERSION =~ tr/_//d;

require Error::TypeTiny;
our @ISA = 'Error::TypeTiny';

sub minimum { $_[0]{minimum} }
sub maximum { $_[0]{maximum} }
sub got     { $_[0]{got} }
sub target  { $_[0]{target} }

sub has_minimum { exists $_[0]{minimum} }
sub has_maximum { exists $_[0]{maximum} }
sub has_target  { exists $_[0]{target} }

sub _build_message {
	my $e = shift;
	
	my $base = 'Wrong number of parameters';
	if ( $e->has_target ) {
		$base .= sprintf( ' to %s', $e->target );
	}
	
	if ( $e->has_minimum and $e->has_maximum and $e->minimum == $e->maximum ) {
		return sprintf(
			"%s; got %d; expected %d",
			$base,
			$e->got,
			$e->minimum,
		);
	}
	elsif ( $e->has_minimum and $e->has_maximum and $e->minimum < $e->maximum ) {
		return sprintf(
			"%s; got %d; expected %d to %d",
			$base,
			$e->got,
			$e->minimum,
			$e->maximum,
		);
	}
	elsif ( $e->has_minimum ) {
		return sprintf(
			"%s; got %d; expected at least %d",
			$base,
			$e->got,
			$e->minimum,
		);
	}
	elsif ( $e->has_maximum ) {
		return sprintf(
			"%s; got %d; expected at most %d",
			$base,
			$e->got,
			$e->maximum,
		);
	}
	else {
		return sprintf(
			"%s; got %d",
			$base,
			$e->got,
		);
	}
} #/ sub _build_message

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Error::TypeTiny::WrongNumberOfParameters - exception for Type::Params

=head1 STATUS

This module is covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

Thrown when a Type::Params compiled check is called with the wrong number
of parameters.

Also thrown by various parameterizable type constraints under similar
circumstances. For example, the C<< HashRef[Int] >> makes sense, but
C<< HashRef[Int, {}] >> does not.

This package inherits from L<Error::TypeTiny>; see that for most
documentation. Major differences are listed below:

=head2 Attributes

=over

=item C<minimum>

The minimum expected number of parameters.

=item C<maximum>

The maximum expected number of parameters.

=item C<got>

The number of parameters actually passed to the compiled check.

=item C<target>

A short string describing what there was the wrong number of parameters for.

=back

=head2 Methods

=over

=item C<has_minimum>, C<has_maximum>, C<has_target>

Predicate methods.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-type-tiny/issues>.

=head1 SEE ALSO

L<Error::TypeTiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
