=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> with deep Dict coercion.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=85911>.

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>.

(Minor changes by Toby Inkster E<lt>tobyink@cpan.orgE<gt>.)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Diab Jerius.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;

BEGIN {
	package MyTypes;

	use Type::Library
		-base,
		-declare => qw[ StrList ];
	use Type::Utils;
	use Types::Standard qw[ ArrayRef Str ];
	declare StrList, as ArrayRef[Str];
	coerce StrList, from Str, via { [$_] };
}

use Type::Params qw[ compile ];
use Types::Standard qw[ Dict slurpy Optional ];

sub foo {
	my $check = compile( slurpy Dict [ foo => MyTypes::StrList ] );
	return [ $check->( @_ ) ];
}

sub bar {
	my $check = compile( MyTypes::StrList );
	return [ $check->( @_ ) ];
}

is_deeply(
	bar( 'b' ),
	[ ["b"] ],
);

is_deeply(
	foo( foo => 'a' ),
	[ { foo=>["a"] } ],
);

done_testing;

