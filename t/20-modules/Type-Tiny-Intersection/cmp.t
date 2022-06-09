=pod

=encoding utf-8

=head1 PURPOSE

Check cmp for Type::Tiny::Intersection.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::TypeTiny;

use Types::Common::Numeric qw(PositiveInt);
use Types::Standard qw(Int Num);

my $Even = Int->create_child_type(name => 'Even', constraint => sub { not $_ % 2 });

my $PositiveEven = $Even & +PositiveInt;

should_pass(2, $PositiveEven);
should_fail(-2, $PositiveEven);
should_fail(1, $PositiveEven);

ok_subtype( Num         ,=> Int, PositiveInt, $Even, $PositiveEven );
ok_subtype( Int         ,=> PositiveInt, $Even, $PositiveEven );
ok_subtype( PositiveInt ,=> $PositiveEven );
ok_subtype( $Even       ,=> $PositiveEven );

ok_subtype(Num->create_child_type, Int, PositiveInt, $Even, $PositiveEven->create_child_type);
ok_subtype(Int->create_child_type, PositiveInt, $Even, $PositiveEven->create_child_type);
ok_subtype(PositiveInt->create_child_type, $PositiveEven->create_child_type);
ok_subtype($Even->create_child_type, $PositiveEven->create_child_type);

ok_subtype($PositiveEven, $PositiveEven->create_child_type);

ok($Even > $PositiveEven, 'Even >');
ok($PositiveEven < $Even, '< Even');
ok(Int > $PositiveEven, 'Int >');
ok($PositiveEven < Int, '< Int');
ok($PositiveEven == $PositiveEven->create_child_type, '==');

done_testing;
