=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Utils declaration functions put types in the caller type registry.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;

BEGIN {
	package Local::Package;
	use Type::Utils -all;
	
	declare 'Reference',
		where { ref $_ };
};

require Type::Registry;
is_deeply(
	[ sort keys %{ Type::Registry->for_class( 'Local::Package' ) } ],
	[ sort qw( Reference ) ],
	'Declaration functions add types to registries',
);

ok(     Type::Registry->for_class( 'Local::Package' )->Reference->check( [] ) );
ok(     Type::Registry->for_class( 'Local::Package' )->Reference->check( {} ) );
ok( not Type::Registry->for_class( 'Local::Package' )->Reference->check( 42 ) );

done_testing;
