=pod

=encoding utf-8

=head1 PURPOSE

Test the C<< ->of >> and C<< ->where >> shortcut methods.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny -all;

use Types::Standard -types;

my $p1 = ArrayRef->parameterize( Int );
my $p2 = ArrayRef->of( Int );

is($p1->{uniq}, $p2->{uniq}, "->of method works same as ->parameterize");

my $p3 = ArrayRef->where(sub { $_->[0] eq 'Bob' });

should_pass ['Bob', 'Alice'], $p3;
should_fail ['Alice', 'Bob'], $p3;

done_testing;
