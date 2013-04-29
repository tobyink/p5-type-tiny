=pod

=encoding utf-8

=head1 PURPOSE

Test positional parameters, a la the example in the documentation:

   sub nth_root
   {
      state $check = compile( Num, Num );
      my ($x, $n) = $check->(@_);
      
      return $x ** (1 / $n);
   }

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Params qw(compile);
use Types::Standard qw(Num);

my $check;
sub nth_root
{
	$check ||= compile( Num, Num );
	[ $check->(@_) ];
}

is_deeply(
	nth_root(1, 2),
	[ 1, 2 ],
	'(1, 2)',
);

is_deeply(
	nth_root("1.1", 2),
	[ "1.1", 2 ],
	'(1.1, 2)',
);

is_deeply(
	nth_root("1.1", "2.2", "3.3"),
	[ "1.1", "2.2" ],
	'(1.1, 2.2, 3.3)',
);

{
	my $e = exception { nth_root() };
	like($e, qr{^Value "" in \$_\[0\] does not meet type constraint "Num"}, '()');
}

{
	my $e = exception { nth_root(1) };
	like($e, qr{^Value "" in \$_\[1\] does not meet type constraint "Num"}, '(1)');
}

{
	my $e = exception { nth_root(undef, 1) };
	like($e, qr{^Value "" in \$_\[0\] does not meet type constraint "Num"}, '(undef, 1)');
}

done_testing;

