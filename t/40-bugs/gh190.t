=pod

=encoding utf-8

=head1 PURPOSE

Test changing C<< $" >> before loading Types::Common.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-type-tiny/issues/190>.

=head1 AUTHOR

Bartosz Jarzyna L<https://github.com/bbrtj>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Bartosz Jarzyna.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

$" = ', ';
require Types::Common;

ok Types::Common::is_Str("");
ok !Types::Common::is_Str(undef);

done_testing;