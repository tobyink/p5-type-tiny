=pod

=encoding utf-8

=head1 PURPOSE

Tests that L<Error::TypeTiny> is capable of providing stack traces.

=head1 DEPENDENCIES

Requires L<Devel::StackTrace>; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Error::TypeTiny ();
local $Error::TypeTiny::StackTrace;

use Test::More;
use Test::Fatal;
use Test::Requires { "Devel::StackTrace" => 0 };

use Types::Standard ();

{
	package Local::Guts;
	
	sub foo {
		local $Error::TypeTiny::StackTrace = 1;
		local $Error::TypeTiny::CarpInternal{'Local::Guts'} = 1;
		Types::Standard::Int->( @_ );
	}
}

sub bar {
	Local::Guts::foo( @_ );
}

sub baz {
	bar( @_ );
}

my $e = exception { baz(undef) };

my $subs = [
	map
		$e->stack_trace->frame( $_ )->subroutine,
		0 .. 2
];

is_deeply(
	$subs,
	[ 'Local::Guts::foo', 'main::bar', 'main::baz' ],
) or diag explain( $subs );

done_testing;
