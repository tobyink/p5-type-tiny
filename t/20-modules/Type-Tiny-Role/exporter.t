=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny::Role can export.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Type::Tiny::Role 'Local::Foo';

{
	package Local::Bar;
	sub DOES { 1 }
}

isa_ok LocalFoo, 'Type::Tiny', 'LocalFoo';

ok is_LocalFoo( bless {}, 'Local::Bar' );

require Type::Registry;
is( 'Type::Registry'->for_me->{'LocalFoo'}, LocalFoo );

done_testing;
