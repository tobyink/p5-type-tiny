=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Eval::TypeTiny> with experimental lexical subs.

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
use Test::Requires 'v5.18';
use Test::Fatal;

use Eval::TypeTiny;

my $variable;
my %env = (
	'$foo'   => do { my $x = "foo"; \$x },
	'@bar'   => [ "bar" ],
	'%baz'   => { "baz" => "1" },
	'&quux'  => sub { $variable },
	'&quuux' => sub { $variable + 40 },
);

my $source = <<'SRC';
sub {
	package Kill::La::NonLexikill;
	return $foo if $_[0] eq '$foo';
	return @bar if $_[0] eq '@bar';
	return %baz if $_[0] eq '%baz';
	return quux() if $_[0] eq '&quux';
	return quuux if $_[0] eq '&quuux';
	return;
}
SRC

my $closure = eval_closure(source => $source, environment => \%env);

is_deeply(
	[ $closure->('$foo') ],
	[ 'foo' ],
	'closure over scalar',
);

is_deeply(
	[ $closure->('@bar') ],
	[ 'bar' ],
	'closure over array',
);

is_deeply(
	[ $closure->('%baz') ],
	[ 'baz' => 1 ],
	'closure over hash',
);

is_deeply(
	[ $closure->('&quux') ],
	[ undef ],
	'closure over lexical sub - undef',
);

$variable = 2;

is_deeply(
	[ $closure->('&quux') ],
	[ 2 ],
	'closure over lexical sub - 2',
);

is_deeply(
	[ $closure->('&quuux') ],
	[ 42 ],
	'closure over lexical sub - 42',
);

my $e = exception { eval_closure(source => 'sub { 1 ]') };

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
	$e->errstr,
	qr{^syntax error},
	'$e->errstr',
);

like(
	$e->code,
	qr{sub \{ 1 \]},
	'$e->code',
);

my $c1 = eval_closure(source => 'sub { die("BANG") }', description => 'test1');
my $e1 = exception { $c1->() };

like(
	$e1,
	qr{^BANG at test1 line 1},
	'"description" option works',
);

my $c2 = eval_closure(source => 'sub { die("BANG") }', description => 'test2', line => 222);
my $e2 = exception { $c2->() };

like(
	$e2,
	qr{^BANG at test2 line 222},
	'"line" option works',
);

done_testing;
