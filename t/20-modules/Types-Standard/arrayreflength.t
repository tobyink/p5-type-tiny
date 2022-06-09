=pod

=encoding utf-8

=head1 PURPOSE

Checks the new ArrayRef[$type, $min, $max] from Types::Standard.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );

use Test::More;
use Test::Fatal;
use Test::TypeTiny;

use Types::Standard qw(ArrayRef Int Any);

my $type = ArrayRef[Int, 2];
should_fail([], $type);
should_fail([0], $type);
should_pass([0..1], $type);
should_pass([0..2], $type);
should_pass([0..3], $type);
should_pass([0..4], $type);
should_pass([0..5], $type);
should_pass([0..6], $type);
should_fail([0..1, "nope"], $type);
should_fail(["nope", 0..1], $type);

$type = ArrayRef[Int, 2, 4];
should_fail([], $type);
should_fail([0], $type);
should_pass([0..1], $type);
should_pass([0..2], $type);
should_pass([0..3], $type);
should_fail([0..4], $type);
should_fail([0..5], $type);
should_fail([0..6], $type);
should_fail([0..1, "nope"], $type);
should_fail(["nope", 0..1], $type);

unlike(ArrayRef->of(Any), qr/for/, 'ArrayRef[Any] optimization');
unlike(ArrayRef->of(Any, 2), qr/for/, 'ArrayRef[Any,2] optimization');
unlike(ArrayRef->of(Any, 2, 4), qr/for/, 'ArrayRef[Any,2,4] optimization');

# diag ArrayRef->of(Any, 2, 4)->inline_check('$XXX');

done_testing;
