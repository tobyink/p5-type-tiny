=pod

=encoding utf-8

=head1 PURPOSE

Fix: "Cannot inline type constraint check" error with compile and Dict.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=86233>.

=head1 AUTHOR

Vyacheslav Matyukhin E<lt>mmcleric@cpan.orgE<gt>.

(Minor changes by Toby Inkster E<lt>tobyink@cpan.orgE<gt>.)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Vyacheslav Matyukhin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
	package Types;
	
	use Type::Library
		-base,
		-declare => qw[ Login ];
	use Type::Utils;
	use Types::Standard qw[ Str ];
	
	declare Login,
		as Str,
		where { /^\w+$/ };
};

use Type::Params qw[ compile ];
use Types::Standard qw[ Dict ];

my $type = Dict[login => Types::Login];

ok not( $type->can_be_inlined );

ok not( $type->coercion->can_be_inlined );

is(exception { compile($type) }, undef);

done_testing;
