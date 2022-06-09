=pod

=encoding utf-8

=head1 PURPOSE

Make sure that the weakening of the reference from a Type::Coercion::Union
object back to its "owner" type constraint does not break functionality.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=92571>.

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Diab Jerius.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL=> 'all';
use Test::More;

use Types::Standard -all;

my $sub = (Str | Str)->coercion;

is(
	$sub->('x'),
	'x',
);

done_testing;
