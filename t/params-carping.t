=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params>' interaction with L<Carp>:

   use Type::Params compile => { confess => 1 };

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

use Type::Params compile => { confess => 1 };
use Types::Standard qw(Int);

my $check;



#line 1 "testsub1.chunk"
sub testsub1
{
	$check ||= compile(Int);
	[ $check->(@_) ];
}

#line 1 "testsub2.chunk"
sub testsub2
{
	testsub1(@_);
}

#line 52 "params-carping.t"
my $e = exception {
	testsub2(1.1);
};

my @e = split /\r?\n|\r/, $e;

like(
	$e[0],
	qr{^Value "1\.1" in \$_\[0\] does not meet type constraint "Int" at testsub2\.chunk line 3},
);

like(
	$e[1],
	qr{^\s+main::testsub2\(1\.1\) called at params-carping.t line 53},
);

done_testing;

