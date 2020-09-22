=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Utils> C<is> function.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use Type::Utils "is" => { -as => "isntnt" };
use Types::Standard "Str";

ok ! isntnt(Str, undef);
ok isntnt(Str, '');
ok ! isntnt('Str', undef);
ok isntnt('Str', '');

done_testing;
