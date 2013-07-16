=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> usage with named parameters and class types.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Params qw(compile);
use Type::Utils;
use Types::Standard -types, "slurpy";

{
	package Test;

	sub new {
		my $class = shift;
		return bless {}, $class;
	}
}


my $chk = compile slurpy Dict[
	foo => class_type { class => 'Test' },
	bar => class_type { class => 'Test' },
	baz => class_type { class => 'Test' },
];

my $t = new_ok 'Test';

is_deeply(
	[ $chk->(foo => $t, bar => $t, baz => $t ) ],
	[ { foo => $t, bar => $t, baz => $t } ]
);

done_testing;

