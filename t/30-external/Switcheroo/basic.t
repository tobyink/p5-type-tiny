=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny works with L<Switcheroo>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires 'Switcheroo';
use Test::Fatal;

use Types::Standard -all;
use Switcheroo;

sub what_is {
	my $var = shift;
	switch ($var) {
		case ArrayRef: 'ARRAY';
		case HashRef:  'HASH';
		default:       undef;
	}
}

is(
	what_is([]),
	'ARRAY',
);

is(
	what_is({}),
	'HASH',
);

is(
	what_is(42),
	undef,
);

is(
	what_is(\(42)),
	undef,
);

done_testing;
