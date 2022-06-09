=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny works with L<match::simple>.

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
use Test::Requires 'match::simple';
use Test::Fatal;

use Types::Standard -all;
use match::simple { replace => 1 };

ok( 42 |M| Int );
ok( 42 |M| Num );
ok not( 42 |M| ArrayRef );

ok( 42 |M| \&is_Int );
ok not( 42 |M| \&is_ArrayRef );

done_testing;
