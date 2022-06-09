=pod

=encoding utf-8

=head1 PURPOSE

Test L<Error::TypeTiny::WrongNumberOfParameters>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Params qw(compile);
use Types::Standard qw(Num Optional slurpy ArrayRef);

my $check1;
sub nth_root
{
	$check1 ||= compile( Num, Num );
	[ $check1->(@_) ];
}

subtest "nth_root()" => sub {
	my $e = exception { nth_root() };
	ok($e->has_minimum);
	is($e->minimum, 2);
	ok($e->has_maximum);
	is($e->maximum, 2);
	is($e->got, 0);
	like($e, qr{^Wrong number of parameters; got 0; expected 2});
};

subtest "nth_root(1)" => sub {
	my $e = exception { nth_root(1) };
	ok($e->has_minimum);
	is($e->minimum, 2);
	ok($e->has_maximum);
	is($e->maximum, 2);
	is($e->got, 1);
	like($e, qr{^Wrong number of parameters; got 1; expected 2});
};

subtest "nth_root(1, 2, 3)" => sub {
	my $e = exception { nth_root(1, 2, 3) };
	ok($e->has_minimum);
	is($e->minimum, 2);
	ok($e->has_maximum);
	is($e->maximum, 2);
	is($e->got, 3);
	like($e, qr{^Wrong number of parameters; got 3; expected 2});
};

my $check2;
sub nth_root_opt
{
	$check2 ||= compile( Num, Optional[Num] );
	[ $check2->(@_) ];
}

subtest "nth_root_opt()" => sub {
	my $e = exception { nth_root_opt() };
	ok($e->has_minimum);
	is($e->minimum, 1);
	ok($e->has_maximum);
	is($e->maximum, 2);
	is($e->got, 0);
	like($e, qr{^Wrong number of parameters; got 0; expected 1 to 2});
};

my $check3;
sub nth_root_slurp
{
	$check3 ||= compile( Num, slurpy ArrayRef[Num] );
	[ $check3->(@_) ];
}

subtest "nth_root_slurp()" => sub {
	my $e = exception { nth_root_slurp() };
	ok($e->has_minimum);
	is($e->minimum, 1);
	ok(!$e->has_maximum);
	is($e->maximum, undef);
	is($e->got, 0);
	like($e, qr{^Wrong number of parameters; got 0; expected at least 1});
};

my $silly = exception {
	Error::TypeTiny::WrongNumberOfParameters->throw(
		minimum   => 3,
		maximum   => 2,
		got       => 0,
	);
};

like($silly, qr{^Wrong number of parameters; got 0}, 'silly exception which should never happen anyway');

my $unspecific = exception {
	Error::TypeTiny::WrongNumberOfParameters->throw(got => 0);
};

like($unspecific, qr{^Wrong number of parameters; got 0}, 'unspecific exception');

done_testing;
