=pod

=encoding utf-8

=head1 PURPOSE

Type::Tiny's C<display_name> should never wrap lines!

=head1 SEE ALSO

L<https://github.com/tobyink/p5-type-tiny/issues/96>.

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
use Types::Standard qw( StrMatch );

my $UUID_RE = qr{
	^
	[0-9a-fA-F]{8}-
	[0-9a-fA-F]{4}-
	[0-9a-fA-F]{4}-
	[0-9a-fA-F]{4}-
	[0-9a-fA-F]{12}
	$
}sxm;

my $type = StrMatch[ $UUID_RE ];

unlike $type->display_name, qr/\n/sm, "don't include linebreaks!";

done_testing;
