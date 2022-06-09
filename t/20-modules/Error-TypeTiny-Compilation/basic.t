=pod

=encoding utf-8

=head1 PURPOSE

Tests for L<Error::TypeTiny::Compilation>, mostly by triggering
compilation errors using L<Eval::TypeTiny>.

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

use Test::More;
use Test::Fatal;

use Eval::TypeTiny;

my $e = exception {
	no warnings qw(void);
	0;
	1;
	2;
#line 38 "basic.t"
	eval_closure(
		source       => 'sub { 1 ]',
		environment  => { '$x' => do { my $x = 42; \$x } },
	);
	3;
	4;
	5;
	6;
};

isa_ok(
	$e,
	'Error::TypeTiny::Compilation',
	'$e',
);

like(
	$e,
	qr{^Failed to compile source because: syntax error},
	'throw exception when code does not compile',
);

like(
	$e->message,
	qr{^Failed to compile source because: syntax error},
	'$e->message',
);

subtest '$e->context' => sub {
	my $ctx = $e->context;
	is($ctx->{package}, 'main',    '$ctx->{package}');
	is($ctx->{file},    'basic.t', '$ctx->{file}');
	ok($ctx->{line} >= 37, '$ctx->{line} >= 37') or diag('line is '.$ctx->{line});
	ok($ctx->{line} <= 42, '$ctx->{line} <= 42') or diag('line is '.$ctx->{line});
};

like(
	$e->errstr,
	qr{^syntax error},
	'$e->errstr',
);

like(
	$e->code,
	qr{sub \{ 1 \]},
	'$e->code',
);

is_deeply(
	$e->environment,
	{ '$x' => do { my $x = 42; \$x } },
	'$e->environment',
);

done_testing;
