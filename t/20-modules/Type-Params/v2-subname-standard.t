=pod

=encoding utf-8

=head1 PURPOSE

Some simple Type::Params usage with C<PERL_TYPE_PARAMS_SUBNAME_PREFIX>
and C<PERL_TYPE_PARAMS_SUBNAME_SUFFIX> both true.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

BEGIN {
	$ENV{PERL_TYPE_PARAMS_SUBNAME_PREFIX} = 'Yes';
	$ENV{PERL_TYPE_PARAMS_SUBNAME_SUFFIX} = 'Please';
};

use Test::More;
use Test::Requires 'Sub::Util';
use Type::Params 'signature_for';
use Types::Common 'Int';

sub add_nums {
	my ( $x, $y ) = @_;
	return $x + $y;
}

my $orig = __PACKAGE__->can('add_nums');
my $sig = signature_for add_nums => (
	pos      => [ Int, Int ],
	returns  => Int,
);
my $wrapped = __PACKAGE__->can('add_nums');

is add_nums(40, 2), 42;
is Sub::Util::subname($orig), 'main::add_nums';
is Sub::Util::subname($wrapped), 'SIGNATURE_FOR::main::add_nums_SIGNATURE';

done_testing;