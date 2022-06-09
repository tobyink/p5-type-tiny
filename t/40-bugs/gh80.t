=pod

=encoding utf-8

=head1 PURPOSE

Test that stringifying Error::TypeTiny doesn't clobber $@.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-type-tiny/issues/80>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt> based on code by @bokutin
L<https://github.com/bokutin>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Type::Tiny;

my $Type1 = Type::Tiny->new( name => "Type1", constraint => sub { 0 } );

eval { $Type1->('val1') };

isa_ok( $@, 'Error::TypeTiny', '$@' );
my $x1 = "$@";
my $x2 = "$@";
like( "$@", qr/did not pass type/, '$@ is still defined and stringifies properly' );

done_testing;
