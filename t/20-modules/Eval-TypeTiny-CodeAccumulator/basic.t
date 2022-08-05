=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Eval::TypeTiny::CodeAccumulator>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

ok( require Eval::TypeTiny::CodeAccumulator );

my $make_adder = 'Eval::TypeTiny::CodeAccumulator'->new(
	description => 'adder',
);

my $n = 40;
my $varname = $make_adder->add_variable( '$addend' => \$n );

is $varname, '$addend';
is $make_adder->add_variable( '$addend' => \999 ), '$addend_2';

$make_adder->add_line( 'sub {' );
$make_adder->increase_indent;
$make_adder->add_placeholder( 'unpack-args' );
$make_adder->add_placeholder( 'dummy' );
$make_adder->add_gap;
$make_adder->add_line( 'return ' . $varname . ' + $other_addend;' );
$make_adder->decrease_indent;
$make_adder->add_line( '}' );

$make_adder->fill_placeholder( 'unpack-args', 'my $other_addend = shift;' );

my $adder = $make_adder->compile;

note( $make_adder->code );

is $adder->( 2 ), 42;

done_testing;
