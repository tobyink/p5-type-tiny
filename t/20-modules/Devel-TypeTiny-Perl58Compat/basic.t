=pod

=encoding utf-8

=head1 PURPOSE

Checks C<< re::is_regexp() >> works.

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
use Types::Standard;

ok(
	+re::is_regexp(qr{foo}),
	're::is_regexp(qr{foo})',
);

ok(
	+re::is_regexp(bless qr{foo}, "Foo"),
	're::is_regexp(bless qr{foo}, "Foo")',
);

done_testing;
