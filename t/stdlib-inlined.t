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

sub inline_check
{
	my ($type, $value) = @_;
		
	return scalar $type->check($value);
}

sub should_pass
{
	my ($value, $type) = @_;
	return note("type '$type' cannot be inlined") unless $type->can_be_inlined;
	
	my $inline = $type->inline_check('$_');
	local $_ = $value;
	
	@_ = (
		!!eval($inline),
		(
			defined $value
				? sprintf("value '%s' passes type constraint '%s' (%s)", $value, $type, $inline)
				: sprintf("undef passes type constraint '%s' (%s)", $type, $inline)
		),
	);
	goto \&Test::More::ok;
}

sub should_fail
{
	my ($value, $type) = @_;
	return note("type '$type' cannot be inlined") unless $type->can_be_inlined;
	
	my $inline = $type->inline_check('$_');
	local $_ = $value;
	
	@_ = (
		!eval($inline),
		(
			defined $value
				? sprintf("value '%s' fails type constraint '%s' (%s)", $value, $type, $inline)
				: sprintf("undef fails type constraint '%s' (%s)", $type, $inline)
		),
	);
	goto \&Test::More::ok;
}

my $var = 123;
should_pass(\$var, ScalarRef);
should_pass([], ArrayRef);
should_pass(+{}, HashRef);
should_pass(sub {0}, CodeRef);
should_pass(\*STDOUT, GlobRef);
should_pass(\(\"Hello"), Ref);
should_pass(\*STDOUT, FileHandle);
should_pass(qr{x}, RegexpRef);
should_pass(1, Str);
should_pass(1, Num);
should_pass(1, Int);
should_pass(1, Defined);
should_pass(1, Value);
should_pass(undef, Undef);
should_pass(undef, Item);
should_pass(undef, Any);
should_pass('Type::Tiny', ClassName);
should_pass('Type::Library', RoleName);

should_pass(undef, Bool);
should_pass('', Bool);
should_pass(0, Bool);
should_pass(1, Bool);
should_fail(7, Bool);
should_pass(\(\"Hello"), ScalarRef);
should_fail('Type::Tiny', RoleName);

should_fail([], Str);
should_fail([], Num);
should_fail([], Int);
should_pass("4x4", Str);
should_fail("4x4", Num);
should_fail("4.2", Int);

should_fail(undef, Str);
should_fail(undef, Num);
should_fail(undef, Int);
should_fail(undef, Defined);
should_fail(undef, Value);

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

should_fail(undef, ClassName);
should_fail([], ClassName);
should_pass("Local::Class$_", ClassName) for 2..4;
should_fail("Local::Dummy1", ClassName);

should_pass([], ArrayRef[Int]);
should_pass([1,2,3], ArrayRef[Int]);
should_fail([1.1,2,3], ArrayRef[Int]);
should_fail([1,2,3.1], ArrayRef[Int]);
should_fail([[]], ArrayRef[Int]);
should_pass([[3]], ArrayRef[ArrayRef[Int]]);
should_fail([["A"]], ArrayRef[ArrayRef[Int]]);

should_pass(undef, Maybe[Int]);
should_pass(123, Maybe[Int]);
should_fail(1.3, Maybe[Int]);

should_pass(bless([], "Local::Class4"), Ref["ARRAY"]);
should_pass(bless({}, "Local::Class4"), Ref["HASH"]);
should_pass([], Ref["ARRAY"]);
should_pass({}, Ref["HASH"]);
should_fail(bless([], "Local::Class4"), Ref["HASH"]);
should_fail(bless({}, "Local::Class4"), Ref["ARRAY"]);
should_fail([], Ref["HASH"]);
should_fail({}, Ref["ARRAY"]);

done_testing;
