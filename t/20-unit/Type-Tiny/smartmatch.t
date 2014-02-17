=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny works with the smartmatch operator.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Type::Tiny ();

BEGIN {
	Type::Tiny::SUPPORT_SMARTMATCH
		or plan skip_all => 'smartmatch support not available for this version or Perl';
}

use Types::Standard -all;

no warnings; # !!

ok( 42 ~~ Int );
ok( 42 ~~ Num );
ok not( 42 ~~ ArrayRef );

ok( 42 ~~ \&is_Int );
ok not( 42 ~~ \&is_ArrayRef );

done_testing;
