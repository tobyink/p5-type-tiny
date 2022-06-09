=pod

=encoding utf-8

=head1 PURPOSE

Fix: Optional constraints ignored if wrapped in Dict.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=86239>.

=head1 AUTHOR

Vyacheslav Matyukhin E<lt>mmcleric@cpan.orgE<gt>.

(Minor changes by Toby Inkster E<lt>tobyink@cpan.orgE<gt>.)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Vyacheslav Matyukhin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Type::Params qw(validate compile);
use Types::Standard qw(ArrayRef Dict Optional Str);

my $i = 0;
sub announce { note sprintf("Test %d ########", ++$i) }
sub got      { note "got: " . join ", ", explain(@_) }

sub f {
	announce();
	got validate(
		\@_,
		Optional[Str],
	);
}

is exception { f("foo") }, undef;
is exception { f() }, undef;
like exception { f(["abc"]) }, qr/type constraint/;

sub g {
	announce();
	got validate(
		\@_,
		Dict[foo => Optional[Str]],
	);
}

is exception { g({ foo => "foo" }) }, undef;
is exception { g({}) }, undef;
like exception { g({ foo => ["abc"] }) }, qr/type constraint/;

done_testing;
