=pod

=encoding utf-8

=head1 PURPOSE

Test to make sure C<compile> keeps a reference to all the types that
get compiled, to avoid them going away before exceptions can be thrown
for them.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=121763>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Types::Standard -types;
use Type::Params qw(compile);

my $x;
my $sub;
my $check;
my $e = exception {
	$sub = sub {
		$check = compile(Dict[key => Int]);
		$check->(@_);
	};
	$sub->({key => 'yeah'});
};

is($e->type->display_name, 'Dict[key=>Int]');

done_testing;
