=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny::Enum's sorter.

=head1 REQUIREMENTS

Requires Perl 5.8 because earlier versions of Perl didn't have stable sort.

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
use Test::Requires '5.008';
use Test::Fatal;

use Type::Tiny::Enum;

my $enum = 'Type::Tiny::Enum'->new(
	name   => 'FooBarBaz',
	values => [qw/ foo bar baz /],
);

is_deeply(
	[ $enum->sort(qw/ xyzzy bar quux baz foo bar quuux /) ],
	[ qw/ foo bar bar baz xyzzy quux quuux / ],
	'sorted',
);

done_testing;
