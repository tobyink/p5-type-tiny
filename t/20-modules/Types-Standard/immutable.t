=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Types::Standard> cannot be added to!

=head1 AUTHOR

Toby Inkster.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Fatal;

use Types::Standard;

my $e = exception {
	Types::Standard->add_type( { name => 'Boomerang' } );
};

like $e, qr/Type library is immutable/;

done_testing;
