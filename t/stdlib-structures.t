=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against structured types from Type::Standard.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );

use Test::More;

use Type::Standard -all;

# avoid prototype
no warnings "redefine";
sub ok { goto \&Test::More::ok }

sub should_pass
{
	my ($value, $type) = @_;
	return (
		!!$type->check($value),
		defined $value
			? sprintf("value '%s' passes type constraint '%s'", $value, $type)
			: sprintf("undef passes type constraint '%s'", $type),
	);
}

sub should_fail
{
	my ($value, $type) = @_;
	return (
		!$type->check($value),
		defined $value
			? sprintf("value '%s' fails type constraint '%s'", $value, $type)
			: sprintf("undef fails type constraint '%s'", $type),
	);
}

my $struct1 = Map[Int, Num];

ok should_pass({1=>111,2=>222}, $struct1);
ok should_pass({1=>1.1,2=>2.2}, $struct1);
ok should_fail({1=>"Str",2=>222}, $struct1);
ok should_pass({1.1=>1,2=>2.2}, $struct1);

done_testing;
