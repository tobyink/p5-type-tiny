=pod

=encoding utf-8

=head1 PURPOSE

Type library used in several test cases.

Defines types C<SmallInteger> and C<BigInteger>. Library extends DemoLib.pm.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package BiggerLib;

use strict;
use warnings;

use Type::Library::Util;

use base "Type::Library";

extends "DemoLib";

declare "SmallInteger",
	as "Integer",
	where { $_ < 10 }
	message { "$_ is too big" };

declare "BigInteger",
	as "Integer",
	where { $_ >= 10 };

1;
