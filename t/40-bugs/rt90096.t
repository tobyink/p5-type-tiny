=pod

=encoding utf-8

=head1 PURPOSE

Make sure that L<Type::Params> localizes C<< $_ >>.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=90096>.

=head1 AUTHOR

Samuel Kaufman E<lt>skaufman@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Samuel Kaufman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL=> 'all';

use Test::More tests => 3;
use Type::Params qw[ compile ];
use Types::Standard qw[ slurpy Dict Bool ];

my $check = compile slurpy Dict [ with_connection => Bool ];

for (qw[ 1 2 3 ]) {  # $_ is read-only in here
	ok $check->( with_connection => 1 );
}
