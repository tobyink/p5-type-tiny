=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against C<CycleTuple> from Types::Standard.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny;

use Types::Standard qw( CycleTuple Int HashRef ArrayRef );
use Type::Utils qw( class_type );

my $type = CycleTuple[Int, HashRef, ArrayRef]

should_pass([], $type);
should_fail([{}], $type);
should_fail([1], $type);
should_fail([1,{}], $type);
should_pass([1,{}, []], $type);
should_fail([1,{}, [], undef], $type);
should_fail([1,{}, [], 2], $type);
should_pass([1,{}, [], 2, {}, []], $type);

done_testing;
