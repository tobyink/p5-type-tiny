=pod

=encoding utf-8

=head1 PURPOSE

Check type constraints can be made inlinable using L<Sub::Quote> even if
Sub::Quote is loaded late.

=head1 DEPENDENCIES

Some parts are skipped if Sub::Quote is not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny;

use Types::Standard qw( ArrayRef Int );

my $type     = ArrayRef[Int];
my $coderef1 = $type->_overload_coderef;
my $coderef2 = $type->_overload_coderef;

is($coderef1, $coderef2, 'overload coderef gets cached instead of being rebuilt');

eval { require Sub::Quote } or do {
	note "Sub::Quote required for further testing";
	done_testing;
	exit(0);
};

my $coderef3 = $type->_overload_coderef;

isnt($coderef3, $coderef1, 'loading Sub::Quote triggers rebuilding overload coderef');

my $coderef4 = $type->_overload_coderef;

is($coderef3, $coderef4, 'overload coderef gets cached again instead of being rebuilt');

done_testing;
