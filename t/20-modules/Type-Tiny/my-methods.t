=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny's C<my_methods> attribute.

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

use Types::Standard qw(Num);

my $type = Num->create_child_type(
	name         => 'Number',
	my_methods   => { round_off => sub { int($_[1]) } }
);

my $type2 = $type->create_child_type(name => 'Number2');

can_ok($_, 'my_round_off') for $type, $type2;
is($_->my_round_off(42.3), 42, "$_ my_round_off works") for $type, $type2;

ok(!$_->can('my_smirnoff'), "$_ cannot my_smirnoff") for $type, $type2;

done_testing;
