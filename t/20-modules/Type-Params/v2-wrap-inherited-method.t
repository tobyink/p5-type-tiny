=pod

=encoding utf-8

=head1 PURPOSE

Check that Type::Params v2 C<signature_for> can find methods to wrap using
inheritance.

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
	package Local::Base;
	sub new {
		my $class = shift;
		bless [], $class;
	}
	sub add_nums {
		return $_[1] + $_[2];
	}
}

{
	package Local::Derived;
	use Types::Common -sigs, -types;
	our @ISA = 'Local::Base';
	
	signature_for add_nums => (
		method     => 1,
		positional => [ Int, Int ],
	);
}

my $o = Local::Derived->new;

is( $o->add_nums( 2, 40 ), 42 );

like(
	exception { $o->add_nums( 40.6, 1.6 ) },
	qr/did not pass type constraint "Int"/,
);

my $o2 = Local::Base->new;
is(
	int( $o2->add_nums( 40.6, 1.6 ) ),
	42,
);

done_testing;
