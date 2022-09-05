=pod

=encoding utf-8

=head1 PURPOSE

More tests for B<StrMatch> from L<Types::Standard>.

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
use Test::Requires '5.020';
use Test::Fatal;
use Test::TypeTiny;
use Types::Standard qw( StrMatch );
use Test::Requires { 'Test::Warnings' => 0.005 };
use Test::Warnings ':all';

#
# This is a regexp containing embedded Perl code.
# It's interesting because it cannot easily be inlined.
#

my $xxx = 0;
my $matchfoo = StrMatch[ qr/f(?{ ++$xxx })oo/ ];

# Wrap this in a warnings block because it will generate warnings under
# EXTENDED_TESTING! The warnings will be tested later.
warnings {
	should_pass('foo', $matchfoo);
	should_fail('bar', $matchfoo);
};

ok($xxx > 0, 'Embedded code executed');
note('$xxx is ' . $xxx);

ok($matchfoo->can_be_inlined, 'It can still be inlined!');
note( $matchfoo->inline_check('$STRING') );

{
	local $Type::Tiny::AvoidCallbacks = 1;
	my $w = warning { $matchfoo->inline_check('$STRING') };
	
	like(
		$w,
		qr/serializing using callbacks/,
		'The inlining needed to use a callback!',
	);
}

#
# Including this mostly for the benefit of Devel::Cover...
#

my $matchfoo2 = StrMatch[ qr/f(?{ ++$xxx })(oo)/, Types::Standard::Enum['oo'] ];
warnings {
	should_pass('foo', $matchfoo);
	should_fail('bar', $matchfoo);
};

{
	local $Type::Tiny::AvoidCallbacks = 1;
	my $w = warning { $matchfoo2->inline_check('$STRING') };
	
	like(
		$w,
		qr/serializing using callbacks/,
		'The inlining needed to use a callback!',
	);
}

done_testing;

