=pod

=encoding utf-8

=head1 PURPOSE

Test a few Type::Params v2 exceptions.

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

use Types::Common -types, -sigs;

subtest "signature extra_arg => ( positional => ... )" => sub {
	my $e = exception {
		my $sig = signature extra_arg => (
			positional => [ Int ],
		);
	};

	ok $e->isa( 'Error::TypeTiny' );
	like $e->message, qr/expected even-sized list/i;
};

subtest "signature_for( positional => ... )" => sub {
	my $e = exception {
		signature_for(
			positional => [ Int ],
		);
	};

	ok $e->isa( 'Error::TypeTiny' );
	like $e->message, qr/expected odd-sized list/i;
};

subtest "signature( named => ..., positional => ... )" => sub {
	my $e = exception {
		my $sig = signature(
			positional => [ Int ],
			named      => [ foo => Int ],
		);
	};

	ok $e->isa( 'Error::TypeTiny' );
	like $e->message, qr/cannot have both positional and named arguments/i;
};

subtest "signature_for bleh => ( named => ..., positional => ... )" => sub {
	my $e = exception {
		signature_for bleh => (
			positional => [ Int ],
			named      => [ foo => Int ],
			goto_next  => sub {},
		);
	};

	ok $e->isa( 'Error::TypeTiny' );
	like $e->message, qr/cannot have both positional and named arguments/i;
};

subtest "signature_for function_does_not_exist => ( positional => ... )" => sub {
	my $e = exception {
		signature_for function_does_not_exist => (
			positional => [ Int ],
		);
	};

	ok $e->isa( 'Error::TypeTiny' );
	like $e->message, qr/not found to wrap/i;
};

subtest "signature()" => sub {
	my $e = exception { signature() };

	ok $e->isa( 'Error::TypeTiny' );
	like $e->message, qr/Signature must be positional, named, or multiple/i;
};

sub bleh333 {}
subtest "signature_for bleh333 => ()" => sub {
	my $e = exception {
		signature_for bleh333 => ();
	};

	ok $e->isa( 'Error::TypeTiny' );
	like $e->message, qr/Signature must be positional, named, or multiple/i;
};

done_testing;
