=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Registry->for_class is automagically populated.

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
use Types::Common::Numeric
	PositiveOrZeroInt => { -as => 'NonNegativeInt' };

ok(
	!$INC{'Type/Registry.pm'},
	'Type::Registry is not automatically loaded',
);

require Type::Registry;
my $reg = Type::Registry->for_me;

ok(
	$reg->lookup('NonNegativeInt') == NonNegativeInt,
	'Type::Registry was auto-populated',
);

done_testing;
