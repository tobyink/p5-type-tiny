=pod

=encoding utf-8

=head1 PURPOSE

Checks role type constraints work.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

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

use BiggerLib qw( :is );

=pod

=encoding utf-8

=head1 PURPOSE

Checks that the check functions exported by a type library work as expected.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

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

use BiggerLib qw( :types );

sub should_pass
{
	my ($value, $type) = @_;
	@_ = (
		!!$type->check($value),
		defined $value
			? sprintf("value '%s' passes type constraint '%s'", $value, $type)
			: sprintf("undef passes type constraint '%s'", $type),
	);
	goto \&Test::More::ok;
}

sub should_fail
{
	my ($value, $type) = @_;
	@_ = (
		!$type->check($value),
		defined $value
			? sprintf("value '%s' fails type constraint '%s'", $value, $type)
			: sprintf("undef fails type constraint '%s'", $type),
	);
	goto \&Test::More::ok;
}

isa_ok(DoesQuux, "Type::Tiny", "DoesQuux");
isa_ok(DoesQuux, "Type::Tiny::Role", "DoesQuux");

should_fail("Foo::Bar"->new, DoesQuux);
should_pass("Foo::Baz"->new, DoesQuux);

should_fail(undef, DoesQuux);
should_fail({}, DoesQuux);
should_fail(FooBar, DoesQuux);
should_fail(FooBaz, DoesQuux);
should_fail(DoesQuux, DoesQuux);
should_fail("Quux", DoesQuux);

done_testing;
