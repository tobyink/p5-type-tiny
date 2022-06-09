=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Utils> C<classifier> function.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;

use Type::Utils qw( classifier );
use Types::Standard -types;

my $classify = classifier(Num, Str, Int, Ref, ArrayRef, HashRef, Any, InstanceOf['Type::Tiny']);

sub classified ($$)
{
	my $got       = $classify->($_[0]);
	my $expected  = $_[1];
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	is(
		$got->name,
		$expected->name,
		sprintf("%s classified as %s", Type::Tiny::_dd($_[0]), $expected),
	);
}

classified(42, Int);
classified(1.1, Num);
classified("Hello world", Str);
classified("42", Int);
classified("1.1", Num);
classified((\(my $x)), Ref);
classified([], ArrayRef);
classified({}, HashRef);
classified(undef, Any);
classified(Num, InstanceOf['Type::Tiny']);

done_testing;
