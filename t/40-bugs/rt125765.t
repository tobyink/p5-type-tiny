=pod

=encoding utf-8

=head1 PURPOSE

Check weird error doesn't happen with deep explain.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=125765>.

=head1 AUTHOR

KB Jørgensen <kbj@capmon.dk>.

Some modifications by Toby Inkster <tobyink@cpan.org>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2022 by KB Jørgensen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Types::Standard qw(Dict Tuple Any);

BEGIN {
	plan skip_all => "cperl's `shadow` warnings catgeory breaks this test; skipping"
		if "$^V" =~ /c$/;
};

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; };

my $type = Dict->of(foo => Any);

my $e = exception {
	$type->assert_valid({ foo => 1, asd => 1 });
};

like($e, qr/Reference .+ did not pass type constraint/, "got correct error for Dict");

is_deeply(\@warnings, [], 'no warnings')
	or diag explain \@warnings;

@warnings = ();

$type = Tuple->of(Any);

$e = exception {
	$type->assert_valid([1, 2]);
};

like($e, qr/Reference .+ did not pass type constraint/, "got correct error for Tuple");

is_deeply(\@warnings, [], 'no warnings')
	or diag explain \@warnings;

done_testing;
