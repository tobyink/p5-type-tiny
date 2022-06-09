=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Coercion overload of C<< ~~ >>.

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
use Type::Tiny ();

BEGIN {
	Type::Tiny::SUPPORT_SMARTMATCH
		or plan skip_all => 'smartmatch support not available for this version or Perl';
}

use Types::Standard qw( Num Int );

my $type = Int->plus_coercions( Num, sub{+int} );

no warnings; #!!

ok     ( 3.1 ~~ $type->coercion );
ok not ( [ ] ~~ $type->coercion );

done_testing;
