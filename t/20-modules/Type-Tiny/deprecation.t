=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny's C<deprecated> attribute works.

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
use Test::Fatal;
use Test::TypeTiny;

use Type::Tiny;

my $t1 = Type::Tiny->new(name => "Base");
my $t2 = Type::Tiny->new(name => "Derived_1", parent => $t1);
my $t3 = Type::Tiny->new(name => "Derived_2", parent => $t1, deprecated => 1);
my $t4 = Type::Tiny->new(name => "Double_Derived_1", parent => $t3);
my $t5 = Type::Tiny->new(name => "Double_Derived_2", parent => $t3, deprecated => 0);

ok not $t1->deprecated;
ok not $t2->deprecated;
ok     $t3->deprecated;
ok     $t4->deprecated;
ok not $t5->deprecated;

done_testing;
