=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Exporter::TypeTiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;

require Types::Standard;

is(
	exception { "Types::Standard"->import("Any") },
	undef,
	q {No exception exporting a legitimate function},
);

can_ok(main => "Any");

like(
	exception { "Types::Standard"->import("kghffubbtfui") },
	qr{^Could not find sub 'kghffubbtfui' to export in package 'Types::Standard'},
	q {Attempt to export a function which does not exist},
);

like(
	exception { "Types::Standard"->import("declare") },
	qr{^Could not find sub 'declare' to export in package 'Types::Standard'},
	q {Attempt to export a function which exists but not in @EXPORT_OK},
);

done_testing;
