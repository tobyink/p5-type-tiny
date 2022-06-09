=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Library warns about deprecated types.

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

BEGIN {
	package Local::Library;
	use Type::Library -base;
	my $t1 = Type::Tiny->new(name => "Base");
	my $t2 = Type::Tiny->new(name => "Derived_1", parent => $t1);
	my $t3 = Type::Tiny->new(name => "Derived_2", parent => $t1, deprecated => 1);
	my $t4 = Type::Tiny->new(name => "Double_Derived_1", parent => $t3);
	my $t5 = Type::Tiny->new(name => "Double_Derived_2", parent => $t3, deprecated => 0);
	__PACKAGE__->meta->add_type($_) for $t1, $t2, $t3, $t4, $t5;
	$INC{'Local/Library.pm'} = __FILE__;
};

{
	my @WARNINGS;
	sub get_warnings { [@WARNINGS] }
	sub reset_warnings { @WARNINGS = () }
	$SIG{__WARN__} = sub { push @WARNINGS, $_[0] };
};

reset_warnings();
eval q{
	package Local::Example1;
	use Local::Library qw(Derived_1);
	1;
} or die($@);
is_deeply(get_warnings(), []);

reset_warnings();
eval q{
	package Local::Example2;
	use Local::Library qw(Derived_2);
	1;
} or die($@);
like(get_warnings()->[0], qr/^Exporting deprecated type Derived_2 to package Local::Example2/);

reset_warnings();
eval q{
	package Local::Example3;
	use Local::Library -allow_deprecated, qw(Derived_2);
	1;
} or die($@);
is_deeply(get_warnings(), []);

done_testing;
