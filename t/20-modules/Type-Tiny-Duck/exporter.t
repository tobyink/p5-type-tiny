=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny::Duck can export.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

{
	package Local::Agent;
	sub get {};
	sub post {};
}

use Type::Tiny::Duck HttpClient => [ 'get', 'post' ];

isa_ok HttpClient, 'Type::Tiny', 'HttpClient';

ok is_HttpClient( bless {}, 'Local::Agent' );

require Type::Registry;
is( 'Type::Registry'->for_me->{'HttpClient'}, HttpClient );

done_testing;
