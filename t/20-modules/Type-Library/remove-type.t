=pod

=encoding utf-8

=head1 PURPOSE

Tests Type::Library's hidden C<_remove_type> method.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Requires 'namespace::clean';
use Test::More;

use Types::Standard ();

# hack
delete( Types::Standard->meta->{immutable} );

# do it!
Types::Standard->_remove_type( Types::Standard::Str() );

ok !Types::Standard->can('Str');
ok !Types::Standard->can('is_Str');
ok !Types::Standard->can('assert_Str');
ok !Types::Standard->can('to_Str');

my %h;
Types::Standard->import( { into => \%h } );

ok !exists $h{Str};
ok !exists $h{is_Str};
ok !exists $h{assert_Str};
ok !exists $h{to_Str};

ok eval 'use Types::Standard -all; 1';

done_testing;
