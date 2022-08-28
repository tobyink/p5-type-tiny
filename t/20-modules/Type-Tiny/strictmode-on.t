=pod

=encoding utf-8

=head1 PURPOSE

Check Type::Tiny C<< / >> overload in strict mode.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN {
	$ENV{$_} = 0 for qw(
		EXTENDED_TESTING
		AUTHOR_TESTING
		RELEASE_TESTING
		PERL_STRICT
	);
	$ENV{PERL_STRICT} = 1;
};

use strict;
use warnings;
use Test::More;
use Test::TypeTiny;

use Types::Standard -types;

subtest "Type constraint object overloading /" => sub {
	my $type = ArrayRef[ Int / Str ];

	should_pass( []                => $type  );
	should_pass( [ 1 .. 3 ]        => $type  );
	should_fail( [ "foo", "bar" ]  => $type  );
	should_fail( [ {} ]            => $type  );
	should_fail( {}                => $type );
};

subtest "Type::Parser support for /" => sub {
	use Type::Registry qw( t );
	my $type = t( 'ArrayRef[ Int / Str ]' );

	should_pass( []                => $type  );
	should_pass( [ 1 .. 3 ]        => $type  );
	should_fail( [ "foo", "bar" ]  => $type  );
	should_fail( [ {} ]            => $type  );
	should_fail( {}                => $type );
};

done_testing;
