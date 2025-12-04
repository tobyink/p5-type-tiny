=pod

=encoding utf-8

=head1 PURPOSE

Test the pre-install and post-install hooks.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

my @GOT;

push @{ $Type::Params::PRE_INSTALL{'Local::Foo'} ||= [] }, sub {
	my $signature = shift;
	push @GOT, pre => $signature->subname;
};

push @{ $Type::Params::POST_INSTALL{'Local::Foo'} ||= [] }, sub {
	my $signature = shift;
	push @GOT, post => $signature->subname;
};

{
	package Local::Foo;
	use Types::Common -all;
	signature_for bar => ( pos => [] );
	sub bar { return 'bar' };
}

is_deeply( \@GOT, [ qw/ pre bar post bar / ] );

done_testing;
