=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against the type constraints from Type::Standard.

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

sub inline_check
{
	my ($type, $value) = @_;
	
	if ($type->can_be_inlined)
	{
		my $inline = $type->inline_check('$_');
		local $_ = $value;
		return scalar eval $inline;
	}
	
	return scalar $type->check($value);
}

sub should_pass
{
	my ($value, $type) = @_;
	return (
		!!inline_check($type, $value),
		(
			!$type->can_be_inlined ? sprintf("type '%s' cannot be inlined anyway", $type) :
			defined $value         ? sprintf("value '%s' passes type constraint '%s'", $value, $type) :
			sprintf("undef passes type constraint '%s'", $type)
		),
	);
}

sub should_fail
{
	my ($value, $type) = @_;
	return (
		!inline_check($type, $value),
		(
			!$type->can_be_inlined ? sprintf("type '%s' cannot be inlined anyway", $type) :
			defined $value         ? sprintf("value '%s' fails type constraint '%s'", $value, $type) :
			sprintf("undef fails type constraint '%s'", $type)
		),
	);
}

my $var = 123;
ok should_pass(\$var, ScalarRef);
ok should_pass([], ArrayRef);
ok should_pass(+{}, HashRef);
ok should_pass(sub {0}, CodeRef);
ok should_pass(\*STDOUT, GlobRef);
ok should_pass(\(\"Hello"), Ref);
ok should_pass(\*STDOUT, FileHandle);
ok should_pass(qr{x}, RegexpRef);
ok should_pass(1, Str);
ok should_pass(1, Num);
ok should_pass(1, Int);
ok should_pass(1, Defined);
ok should_pass(1, Value);
ok should_pass(undef, Undef);
ok should_pass(undef, Item);
ok should_pass(undef, Any);
ok should_pass('Scalar::should_pass', ClassName);
ok should_pass('Scalar::should_pass', RoleName);

ok should_pass(undef, Bool);
ok should_pass('', Bool);
ok should_pass(0, Bool);
ok should_pass(1, Bool);
ok should_fail(7, Bool);
ok should_pass(\(\"Hello"), ScalarRef);

ok should_fail([], Str);
ok should_fail([], Num);
ok should_fail([], Int);
ok should_pass("4x4", Str);
ok should_fail("4x4", Num);
ok should_fail("4.2", Int);

ok should_fail(undef, Str);
ok should_fail(undef, Num);
ok should_fail(undef, Int);
ok should_fail(undef, Defined);
ok should_fail(undef, Value);

{
	package Local::Class1;
	use strict;
}

{
	no warnings 'once';
	$Local::Class2::VERSION = 0.001;
	@Local::Class3::ISA     = qw(UNIVERSAL);
	@Local::Dummy1::FOO     = qw(UNIVERSAL);
}

{
	package Local::Class4;
	sub XYZ () { 1 }
}

ok should_fail(undef, ClassName);
ok should_fail([], ClassName);
ok should_pass("Local::Class$_", ClassName) for 2..4;
ok should_fail("Local::Dummy1", ClassName);

ok should_pass([], ArrayRef[Int]);
ok should_pass([1,2,3], ArrayRef[Int]);
ok should_fail([1.1,2,3], ArrayRef[Int]);
ok should_fail([1,2,3.1], ArrayRef[Int]);
ok should_fail([[]], ArrayRef[Int]);
ok should_pass([[3]], ArrayRef[ArrayRef[Int]]);
ok should_fail([["A"]], ArrayRef[ArrayRef[Int]]);

ok should_pass(undef, Maybe[Int]);
ok should_pass(123, Maybe[Int]);
ok should_fail(1.3, Maybe[Int]);

done_testing;
