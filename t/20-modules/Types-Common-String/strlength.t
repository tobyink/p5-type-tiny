=pod

=encoding utf-8

=head1 PURPOSE

Tests constraints for L<Types::Common::String>'s
C<StrLength>tring

=head1 AUTHOR

Toby Inkster.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2022 by Toby Inkster.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use utf8;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::TypeTiny;

use Types::Common::String -all;

my $type = StrLength[5,10];

should_fail($_, $type) for ([], {}, sub { 3 }, undef, "", 123, "Hiya", "Hello World");
should_pass($_, $type) for ("Hello", "Hello!", " " x 8, "HelloWorld");

my $type2 = StrLength[4,4];

should_pass("café", $type2);
should_pass("™ķ⁹—", $type2);

my $type3 = StrLength[4];
should_fail($_, $type3) for ([], {}, sub { 3 }, undef, "", 123);
should_pass($_, $type3) for ("Hello", "Hello!", " " x 8, "HelloWorld", "Hiya", "Hello World");

done_testing;
