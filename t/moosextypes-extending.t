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

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Requires { "MooseX::Types::Moose" => "0.35" };
use Test::TypeTiny;

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

done_testing;
