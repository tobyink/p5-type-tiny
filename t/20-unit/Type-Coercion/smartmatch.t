=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Coercion overload of C<< ~~ >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;

BEGIN {
	$] <  5.010001 ? plan(skip_all => "Perl too old") :
	$] >= 5.021000 ? plan(skip_all => "Perl too new") :
	$] >= 5.018000 ? warnings->unimport('experimental::smartmatch') :
	();
};

use Types::Standard qw( Num Int );

my $type = Int->plus_coercions( Num, sub{+int} );

ok     ( 3.1 ~~ $type->coercion );
ok not ( [ ] ~~ $type->coercion );

done_testing;
