=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Parser works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny;

use Type::Parser qw(_std_eval);
use Types::Standard -types;

sub types_equal
{
	my ($a, $b) = map { ref($_) ? $_ : _std_eval($_) } @_;
	my ($A, $B) = map { $_->inline_check('$X') } ($a, $b);
	my $msg = "$_[0] eq $_[1]";
	@_ = ($A, $B, $msg);
	goto \&Test::More::is;
}

types_equal("Int", "Int");
types_equal("(Int)", "Int");
types_equal("Int", Int);

done_testing;
