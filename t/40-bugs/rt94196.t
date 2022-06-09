=pod

=encoding utf-8

=head1 PURPOSE

Problematic inlining using C<< $_ >>.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=94196>.

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Diab Jerius.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL=> 'all';
use Test::More;
use Test::Fatal;

use Type::Params qw( validate );
use Types::Standard qw( -types slurpy );

{
	package Foo;
	sub new { bless {}, shift }
	sub send { }
};

my $type = Dict[ encoder => HasMethods ['send'] ];

is(
	exception {
		my @params = ( encoder => Foo->new );
		validate(\@params, slurpy($type));
	},
	undef,
	"slurpy Dict w/ HasMethods",
) or note( $type->inline_check('$_') );

done_testing;
