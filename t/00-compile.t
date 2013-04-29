=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Tiny, Type::Library and Type::Utils compile.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use_ok("Eval::TypeTiny");
use_ok("Exporter::TypeTiny");
use_ok("Test::TypeTiny");
use_ok("Type::Coercion");
use_ok("Type::Coercion::Union");
use_ok("Type::Library");
use_ok("Types::Standard");
use_ok("Types::TypeTiny");
use_ok("Type::Tiny");
use_ok("Type::Tiny::Class");
use_ok("Type::Tiny::Duck");
use_ok("Type::Tiny::Enum");
use_ok("Type::Tiny::Intersection");
use_ok("Type::Tiny::Role");
use_ok("Type::Tiny::Union");
use_ok("Type::Utils");
use_ok("Type::Params");

done_testing;

