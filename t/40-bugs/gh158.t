=pod

=encoding utf-8

=head1 PURPOSE

Ensure no warning on certain shallow stack traces.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-type-tiny/issues/158>.

=head1 AUTHOR

Diab Jerius L<https://github.com/djerius>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2024 by Diab Jerius.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Types::Common -types, -sigs;

use Test::Requires { 'Test::Warnings' => 0.005 };
use Test::Warnings ':all';

my $e;

signature_for get_products => (
	named   => [ bar => Optional[Str] ],
	on_die  => sub { $e = shift },
);

sub get_products {}

get_products( rs => 3 );

like( $e->message, qr/^Unrecognized parameter/ );

done_testing;
