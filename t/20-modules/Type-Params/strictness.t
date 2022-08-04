=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> C<strictness> option.

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

use Type::Params qw(compile);
use Types::Standard -types;

my $check = compile(
	{ strictness => '$::CHECK_TYPES' },
	Int,
	ArrayRef,
);

note compile(
	{ strictness => '$::CHECK_TYPES', want_source => 1 },
	Int,
	ArrayRef,
);

note compile(
	{ strictness => 1, want_source => 1 },
	Int,
	ArrayRef,
);

note compile(
	{ strictness => 1, want_source => 1 },
	Int,
	ArrayRef,
);

# Type checks are skipped
{
	local $::CHECK_TYPES = 0;
	my $e = exception {
		my ( $number, $list ) = $check->( {}, {} );
		my ( $numbe2, $lis2 ) = $check->();
	};
	is $e, undef;
}

# Type checks are performed
{
	local $::CHECK_TYPES = 1;
	my $e = exception {
		my ( $number, $list ) = $check->( {}, {} );
	};
	like $e, qr/did not pass type constraint "Int"/;
}

my $check2 = compile(
	{ strictness => '$::CHECK_TYPES' },
	Int,
	ArrayRef, { strictness => 1 }
);

# Type check for Int is skipped
{
	local $::CHECK_TYPES = 0;
	my $e = exception {
		my ( $number, $list ) = $check2->( {}, [] );
	};
	is $e, undef;
}

# Type check for ArrayRef is performed
{
	local $::CHECK_TYPES = 0;
	my $e = exception {
		my ( $number, $list ) = $check2->( {}, {} );
	};
	like $e, qr/did not pass type constraint "ArrayRef"/;
}

done_testing;
