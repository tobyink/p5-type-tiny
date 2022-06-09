=pod

=encoding utf-8

=head1 PURPOSE

Type library used in several test cases.

Defines types C<String>, C<Number> and C<Integer>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package DemoLib;

use strict;
use warnings;

use Scalar::Util "looks_like_number";
use Type::Utils;

use Type::Library -base;

declare "String",
	where { no warnings; not ref $_ }
	message { "is not a string" };

declare "Number",
	as "String",
	where { no warnings; looks_like_number $_ },
	message { "'$_' doesn't look like a number" };

declare "Integer",
	as "Number",
	where { no warnings; $_ eq int($_) };

1;
