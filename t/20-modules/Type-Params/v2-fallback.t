=pod

=encoding utf-8

=head1 PURPOSE

Test the C<< fallback >> option for modern Type::Params v2 API.

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
use Test::Fatal;

use Types::Common -types;
use Type::Params -sigs;

sub xyz {
	return 666;
}

signature_for [ 'xyz' ] => (
	pos      => [ Int, Int ],
	fallback => sub { $_[0] + $_[1] },
);

is( xyz( 40, 2 ), 666 );

signature_for [ 'abc' ] => (
	pos      => [ Int, Int ],
	fallback => sub { $_[0] + $_[1] },
);

is( abc( 40, 2 ), 42 );

done_testing;
