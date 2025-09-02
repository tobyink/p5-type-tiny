=pod

=encoding utf-8

=head1 PURPOSE

Ensure that Type::Tiny::Union's C<all> method works when Moose is loaded.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-type-tiny/issues/180>.

=head1 AUTHOR

Robert Moore L<https://github.com/robert-moore96>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Robert Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

{
	package Local::Dummy;
	use Test::Requires 'Moose';
	use Test::Requires 'Moose::Meta::TypeConstraint';
	use Test::Requires 'Moose::Meta::TypeConstraint::Union';
};

use Types::Standard qw/Str Int/;

my $type = Str|Int;
my @data = (1,'test');

ok $type->all(@data);

done_testing;
