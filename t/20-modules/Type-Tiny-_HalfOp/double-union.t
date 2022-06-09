=pod

=encoding utf-8

=head1 PURPOSE

Ensure that the following works:

   ArrayRef[Str] | Undef | Str

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL => 'all';
use Test::More;

use Types::Standard -all;

my $union = eval { ArrayRef[Str] | Undef | Str };

SKIP: {
	ok $union or skip 'broken type', 6;
	ok $union->check([qw/ a b /]);
	ok !$union->check([[]]);
	ok $union->check(undef);
	ok $union->check("a");
	ok !$union->check([undef]);
	ok !$union->check({});
}

done_testing;
