=pod

=encoding utf-8

=head1 PURPOSE

Check that people doing silly things with Test::Params get 

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Params qw( compile );
use Types::Standard qw( Optional Int ArrayRef slurpy );

like(
	exception { compile(Optional[Int], Int) },
	qr{^Non-Optional parameter following Optional parameter},
	"Cannot follow an optional parameter with a required parameter",
);

like(
	exception { compile(slurpy ArrayRef[Int], Optional[Int]) },
	qr{^Parameter following slurpy parameter},
	"Cannot follow a slurpy parameter with anything",
);

is(
	exception { compile(slurpy Int) },
	undef,
	"This makes no sense, but no longer throws an exception",
);

done_testing;

