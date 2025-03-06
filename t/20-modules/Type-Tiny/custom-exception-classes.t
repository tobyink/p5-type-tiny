=pod

=encoding utf-8

=head1 PURPOSE

Test Type::Tiny's C<exception_class> attribute.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Types::Standard qw( Int );

{
	package Custom::Exception;
	use base 'Error::TypeTiny::Assertion';
}

my $type1 = Int->create_child_type(
	constraint      => q{ $_ > 3 },
	exception_class => 'Custom::Exception',
);

my $type2 = $type1->create_child_type(
	constraint      => q{ $_ < 5 },
);

$type1->assert_valid( 4 );
$type2->assert_valid( 4 );

{
	my $e = exception {
		$type1->assert_valid( 2 );
	};
	isa_ok( $e, 'Custom::Exception' );
}

{
	my $e = exception {
		$type2->assert_valid( 6 );
	};
	isa_ok( $e, 'Custom::Exception' );
}

# The inlined code includes the exception_class.
note( $type2->inline_assert( '$value' ) );

done_testing;
