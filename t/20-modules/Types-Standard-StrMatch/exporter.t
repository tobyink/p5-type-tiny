=pod

=encoding utf-8

=head1 PURPOSE

Checks Types::Standard::StrMatch can export.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Types::Standard -types;
use Types::Standard::StrMatch (
	Aaa => { of => qr/\A[Aa]+\z/ },
	Bbb => { re => qr/\A[Bb]+\z/ },
);

is Aaa->name, "Aaa";
is Bbb->name, "Bbb";

ok is_Aaa 'AaaaaaaAAAAaaAaAAAaaaA';
ok is_Bbb 'BbbbBbbBbBbBBBbBBBB';
ok !is_Aaa \1.1;
ok !is_Bbb "a";

require Type::Registry;
is( 'Type::Registry'->for_me->{'Aaa'}, Aaa );
is( 'Type::Registry'->for_me->{'Bbb'}, Bbb );

done_testing;
