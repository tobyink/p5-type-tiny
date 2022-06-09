=pod

=encoding utf-8

=head1 PURPOSE

Additional tests related to RT#90096.

Make sure that L<Type::Params> localizes C<< $_ >>.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=90096>.

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Diab Jerius.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Type::Params qw[ compile ];
use Types::Standard -all;

{
	my $check = compile( Dict [ a => Num ] );
	grep { $_->( { a => 3 } ) } $check;
	is( ref $check, 'CODE', "check is still code" );
}

{
	my $check = compile( slurpy Dict [ a => Num ] );
	grep { $_->( a => 3 ) } $check;
	is( ref $check, 'CODE', "slurpy check is still code" );
}

done_testing;
