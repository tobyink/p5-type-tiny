=pod

=encoding utf-8

=head1 PURPOSE

Check type constraints work with L<Object::Accessor>.

=head1 DEPENDENCIES

Test is skipped if Object::Accessor 0.30 is not available.

=head1 CAVEATS

As of Perl 5.17.x, the Object::Accessor module is being de-cored, so will
issue deprecation warnings. These can safely be ignored for the purposes
of this test case. Object::Accessor from CPAN does not have these warnings.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires { "Object::Accessor" => 0.30 };
use Test::Fatal;

use Types::Standard "Int";
use Object::Accessor;

my $obj = Object::Accessor->new;
$obj->mk_accessors(
	{ foo => Int->compiled_check },
);

$obj->foo(12);
is($obj->foo, 12);

my $e = exception {
	local $Object::Accessor::FATAL = 1;
	$obj->foo("Hello");
};
like($e, qr{^'Hello' is an invalid value for 'foo'});

done_testing;
