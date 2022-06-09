=pod

=encoding utf-8

=head1 PURPOSE

The "too few arguments for type constraint check functions" error.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=97684>.

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Diab Jerius.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $ENV{'DEVEL_HIDE_VERBOSE'} = 0 };

use strict;
use warnings;
use Test::More;
use Test::Requires 'Devel::Hide';
use Test::Requires { Mouse => '1.0000' };

use Devel::Hide qw(Type::Tiny::XS);

{
	package Local::Class;
	use Mouse;
}

{
	package Local::Types;
	use Type::Library -base, -declare => qw( Coord ExistingCoord );
	use Type::Utils -all;
	use Types::Standard -all;
	
	declare ExistingCoord, as Str, where { 0 };
	
	declare Coord, as Str;
}

use Types::Standard -all;
use Type::Params qw( validate );

validate(
	[],
	slurpy Dict[ with => Optional[Local::Types::ExistingCoord] ],
);

ok 1;
done_testing;
