=pod

=encoding utf-8

=head1 PURPOSE

Fix "Malformed UTF-8 character" warnings in Perl 5.10 with utf8 pragma on

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=101582>.

=head1 AUTHOR

André Walker <andre@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015 by André Walker

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Fatal;

use Types::Standard qw/Dict Int/; # could've been anything instead of Int
use Type::Params qw/compile/;
use Test::More;
use Test::Fatal;

local $SIG{__WARN__} = sub { die @_ };

unlike(
    exception { compile( Dict [ foo => Int ] ) },
    qr/Malformed UTF-8 character/,
    q/Didn't get the "Malformed UTF-8" warning/,
);

done_testing;
