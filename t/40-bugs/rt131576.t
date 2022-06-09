=pod

=encoding utf-8

=head1 PURPOSE

Test that inlined type checks don't generate issuing warning when compiled
in packages that override built-ins.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=131576>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires { 'Test::Warnings' => 0.005 };
use Test::Warnings;

{
	package Local::Dummy1;
	use Test::Requires 'Moo';
	use Test::Requires 'MooX::TypeTiny';
}

BEGIN { $ENV{PERL_ONLY} = 1 };   # no XS

{
	package Foo;
	use Moo;
	use MooX::TypeTiny;
	use Types::Standard qw(HashRef Str);
	has _data => (
		is       => 'ro',
		isa      => HashRef[Str],
		required => 1,
		init_arg => 'data',
	);
	sub values {
		@_==1 or die 'too many parameters';
		CORE::values %{shift->_data};
	}
	sub keys {
		@_==1 or die 'too many parameters';
		CORE::keys %{shift->_data};
	}
}

my $obj = Foo->new(data => {foo => 42});
print "$_\n" for $obj->values;

ok 1;

done_testing;
