=pod

=encoding utf-8

=head1 PURPOSE

Check that L<Type::Library> can extend an existing L<MooseX::Types>
type constraint library.

=head1 DEPENDENCIES

MooseX::Types 0.35; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Requires { "MooseX::Types::Moose" => "0.35" };
use Test::TypeTiny;
use Test::Fatal;

BEGIN {
	package MyTypes;
	use Type::Library -base, -declare => qw(NonEmptyStr);
	use Type::Utils -all;
	BEGIN { extends 'MooseX::Types::Moose', 'Types::TypeTiny' };
	
	declare NonEmptyStr, as Str, where { length($_) };
	
	$INC{'MyTypes.pm'} = __FILE__;
};

use MyTypes -types;

should_pass("foo", Str);
should_pass("", Str);
should_pass("foo", NonEmptyStr);
should_fail("", NonEmptyStr);
should_pass({}, HashLike);
should_fail([], HashLike);

{
	package MyDummy;
	use Moose;
	$INC{'MyDummy.pm'} = __FILE__;
	
	package MoreTypes;
	use Type::Library -base;
	
	::like(
		::exception { Type::Utils::extends 'MyDummy' },
		qr/not a type constraint library/,
		'cannot extend non-type-library',
	);
}

BEGIN {
	package MyMooseTypes;
	use MooseX::Types -declare => ['RoundedInt'];
	use MooseX::Types::Moose qw(Int Num);
	subtype RoundedInt, as Int;
	coerce RoundedInt, from Num, via { int($_) };
	$INC{'MyMooseTypes.pm'} = __FILE__;
};

{
	package Local::XYZ1234;
	use MyMooseTypes qw(RoundedInt);
	::is( RoundedInt->coerce(3.1), 3, 'MooseX::Types coercion works as expected' );
}

BEGIN {
	package MyTinyTypes;
	use Type::Library -base;
	use Type::Utils 'extends';
	extends 'MyMooseTypes';
	$INC{'MyTinyTypes.pm'} = __FILE__;
};

{
	package Local::XYZ12345678;
	use MyTinyTypes qw(RoundedInt);
	::is( RoundedInt->coerce(3.1), 3, 'Type::Tiny coercion works built from MooseX::Types extension' );
}

done_testing;
