=pod

=encoding utf-8

=head1 PURPOSE

Checks type libraries put types in their own type registries.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;

BEGIN {
	package Local::Library;
	use Type::Library -base;
	use Type::Tiny;
	my $t1 = Type::Tiny->new(name => "Base");
	my $t2 = Type::Tiny->new(name => "Derived_1", parent => $t1);
	my $t3 = Type::Tiny->new(name => "Derived_2", parent => $t1, deprecated => 1);
	my $t4 = Type::Tiny->new(name => "Double_Derived_1", parent => $t3);
	my $t5 = Type::Tiny->new(name => "Double_Derived_2", parent => $t3, deprecated => 0);
	__PACKAGE__->meta->add_type($_) for $t1, $t2, $t3, $t4, $t5;
};

require Type::Registry;
is_deeply(
	[ sort keys %{ Type::Registry->for_class( 'Local::Library' ) } ],
	[ sort qw( Base Derived_1 Derived_2 Double_Derived_1 Double_Derived_2 ) ],
	'Type libraries automatically put types into their own registry',
);

done_testing;
