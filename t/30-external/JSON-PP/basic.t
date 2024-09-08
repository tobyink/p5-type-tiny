=pod

=encoding utf-8

=head1 PURPOSE

Check B<Bool> and B<BoolLike> type constraints against JSON::PP's bools.

=head1 DEPENDENCIES

Requires JSON::PP.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023-2024 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires { "JSON::PP" => "4.00" };
use Test::TypeTiny;

use Types::Common qw( Bool BoolLike );

should_pass( $_, Bool ) for 0, 1, "", undef;
should_fail( $_, Bool ) for $JSON::PP::true, $JSON::PP::false, \0, \1;

is( Bool->coerce($JSON::PP::true),  !!1, 'Bool coercion of JSON::PP::true'  );
is( Bool->coerce($JSON::PP::false), !!0, 'Bool coercion of JSON::PP::false' );

should_pass( $_, BoolLike ) for 0, 1, "", undef, $JSON::PP::true, $JSON::PP::false;
should_fail( $_, Bool ) for \0, \1;

done_testing;
