=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny::Enum can export.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022-2024 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Type::Tiny::Enum Status => [ 'alive', 'dead' ];

isa_ok Status, 'Type::Tiny', 'Status';

ok is_Status( STATUS_DEAD );
ok is_Status( STATUS_ALIVE );

require Type::Registry;
is( 'Type::Registry'->for_me->{'Status'}, Status );

done_testing;
