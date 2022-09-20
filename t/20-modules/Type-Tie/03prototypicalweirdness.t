=pod

=encoding utf-8

=head1 PURPOSE

Test that C<ttie> prototype works.

Test case suggested by Graham Knop (HAARG).

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2018-2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use Type::Tie;
use Types::Standard qw( ArrayRef Num );

ttie my $foo, ArrayRef[Num], [1,2,3];

is_deeply(
	$foo,
	[1..3],
);

done_testing;
