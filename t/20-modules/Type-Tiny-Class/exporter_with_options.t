=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny::Class can export.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Type::Tiny::Class HT => { class => 'HTTP::Tiny' };

isa_ok HT, 'Type::Tiny', 'HT';

ok is_HT( bless {}, 'HTTP::Tiny' );

require Type::Registry;
is( 'Type::Registry'->for_me->{'HT'}, HT );

done_testing;
