=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Tie works with a home-made type constraint system
conforming to L<Type::API>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2018-2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Tie;

use constant Int => do {
	package Local::Type::Int;
	sub DOES {
		return 1 if $_[1] eq "Type::API::Constraint";
		return 1 if $_[1] eq "Type::API::Constraint::Coercible";
		shift->SUPER::DOES(@_);
	}
	sub check {
		defined($_[1]) && $_[1] =~ /\A-?[0-9]+\z/;
	}
	sub get_message {
		defined($_[1])
			? "Value \"$_[1]\" does not meet type constraint Int"
			: "Undef does not meet type constraint Int"
	}
	my $x;
	bless \$x;
};

use constant Rounded => do {
	package Local::Type::Rounded;
	our @ISA = 'Local::Type::Int';
	sub has_coercion {
		1;
	}
	sub coerce {
		defined($_[1]) && !ref($_[1]) && $_[1] =~ /\A[Ee0-9.-]+\z/
			? int($_[1])
			: $_[1];
	}
	my $x;
	bless \$x;
};

ttie my $count, Rounded, 0;

$count++;            is($count, 1);
$count = 2;          is($count, 2);
$count = 3.14159;    is($count, 3);

like(
	exception { $count = "Monkey!" },
	qr{^Value "Monkey!" does not meet type constraint Int},
);

ttie my @numbers, Rounded, 1, 2, 3.14159;

unshift @numbers, 0.1;
$numbers[4] = 4.4;
push @numbers, scalar @numbers;

is_deeply(
	\@numbers,
	[ 0..5 ],
);

like(
	exception { push @numbers, 1, 2.2, 3, "Bad", 4 },
	qr{^Value "Bad" does not meet type constraint Int},
);

like(
	exception { unshift @numbers, 1, 2.2, 3, "Bad", 4 },
	qr{^Value "Bad" does not meet type constraint Int},
);

like(
	exception { $numbers[2] .= "Bad" },
	qr{^Value "2Bad" does not meet type constraint Int},
);

is_deeply(
	\@numbers,
	[ 0..5 ],
);

ttie my %stuff, Int, foo => 1;
$stuff{bar} = 2;

is_deeply(
	\%stuff,
	{ foo => 1, bar => 2 },
);

like(
	exception { $stuff{baz} = undef },
	qr{^Undef does not meet type constraint Int},
);

delete $stuff{bar};

is_deeply(
	\%stuff,
	{ foo => 1 },
);

done_testing;
