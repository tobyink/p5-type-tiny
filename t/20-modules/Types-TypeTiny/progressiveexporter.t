# HARNESS-NO-PRELOAD

=pod

=encoding utf-8

=head1 PURPOSE

Checks that Types::TypeTiny avoids loading Exporter::Tiny.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;

require Types::TypeTiny;

ok !Exporter::Tiny->can('mkopt');

Types::TypeTiny->import();

ok !Exporter::Tiny->can('mkopt');

Types::TypeTiny->import('HashLike');

ok Exporter::Tiny->can('mkopt');

done_testing;
