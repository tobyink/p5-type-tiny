=pod

=encoding utf-8

=head1 PURPOSE

Stuff that was originally in basic.t but was split out to avoid basic.t
requiring Moose and Mouse.

=head1 DEPENDENCIES

This test requires L<Moose> 2.0000 and L<Mouse> 1.00. Otherwise, it is
skipped.

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

# Test::Requires calls ->import on Moose/Mouse, so be sure
# to import them into dummy packages.
{ package XXX; use Test::Requires { Moose => '2.0000' } };
{ package YYY; use Test::Requires { Mouse => '1.00' } };

use Test::More;
use Test::TypeTiny -all;
use Types::TypeTiny -all;
use Moose::Util::TypeConstraints qw(find_type_constraint);

subtest "TypeTiny" => sub
{
	my $type = TypeTiny;
	should_pass( ArrayLike, $type, 'Type::Tiny constraint object passes type constraint TypeTiny' );
	should_fail( {}, $type );
	should_fail( sub { 42 }, $type );
	should_fail( find_type_constraint("Int"), $type, 'Moose constraint object fails type constraint TypeTiny' );
	should_fail( Mouse::Util::TypeConstraints::find_type_constraint("Int"), $type, 'Mouse constraint object fails type constraint TypeTiny' );
	should_fail( undef, $type );
};

done_testing;
