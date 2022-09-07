=pod

=encoding utf-8

=head1 PURPOSE

Check that Type::Params v2 default coderefs get passed an invocant.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
	package Local::FooBar;
	use Types::Common -types, -sigs;
	sub foo { 42 }
	my $check;
	sub bar {
		$check ||= signature(
			method     => 1,
			positional => [
				Int, { default => sub { shift->foo } },
			],
		);
		my ( $self, $num ) = &$check;
		return $num / 2;
	}
}

my $object = bless {}, 'Local::FooBar';

is( $object->bar, 21 );

is( $object->bar(666), 333 );

done_testing;
