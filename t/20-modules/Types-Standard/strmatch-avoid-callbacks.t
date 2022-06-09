=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against C<StrMatch> from Types::Standard
when C<< $Type::Tiny::AvoidCallbacks >> is true.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );
use Test::More;

BEGIN {
	plan skip_all => "cperl's `shadow` warnings catgeory breaks this test; skipping"
		if "$^V" =~ /c$/;
};

use Test::Requires '5.020';
use Test::Requires 'Test::Warnings';

use Types::Standard 'StrMatch';
use Test::Warnings 'warning';

$Type::Tiny::AvoidCallbacks = 1;

my $z;
my $complex = StrMatch->of(qr/x(?{$z})/);  # closure so can't be easily inlined
my $warning = warning { $z = $complex->inline_check('$VALUE') };

like($z, qr/Types::Standard::StrMatch::expressions/);
like($warning, qr/without callbacks/);

done_testing;
