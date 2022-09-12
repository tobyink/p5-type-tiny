=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Eval::TypeTiny>.

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

subtest "constants exist" => sub {
	my @constants = qw(
		HAS_LEXICAL_SUBS
		ALIAS_IMPLEMENTATION
		IMPLEMENTATION_DEVEL_LEXALIAS
		IMPLEMENTATION_PADWALKER
		IMPLEMENTATION_NATIVE
		IMPLEMENTATION_TIE
	);
	for my $c (@constants) {
		subtest "constant $c" => sub {
			my $can = Eval::TypeTiny->can($c);
			ok $can, "constant $c exists";
			is exception { $can->() }, undef, "... and doesn't throw an error";
			is $can->(undef), $can->(999), "... and seems to be constant";
		};
	}
};

my $s = <<'SRC';
sub {
	return $foo if $_[0] eq '$foo';
	return @bar if $_[0] eq '@bar';
	return %baz if $_[0] eq '%baz';
	return;
}
SRC

my %sources = (string => $s, arrayref => [split /\n/, $s]);

foreach my $key (reverse sort keys %sources) {
	subtest "compiling $key source" => sub {
		my %env = (
			'$foo' => do { my $x = "foo"; \$x },
			'@bar' => [ "bar" ],
			'%baz' => { "baz" => "1" },
		);

		my $source  = $sources{$key};
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
	};
}

my $external = 40;
my $closure2 = eval_closure(
	source      => 'sub { $xxx += 2 }',
	environment => { '$xxx' => \$external },
	alias       => 1,
);

$closure2->();
is($external, 42, 'closing over variables really really really works!');

if ("$^V" =~ /c$/) {
	diag "cperl: skipping variable destruction test";
}

else {
	my $destroyed = 0;
	{
		package MyIndicator;
		sub DESTROY { $destroyed++ }
	}
		
	subtest 'closed over variables disappear on cue' => sub {
		
		{
			my $number = bless \(my $foo), "MyIndicator";
			$$number = 40;
			my $closure = eval_closure(
				source       => 'sub { $$xxx += 2 }',
				environment  => { '$xxx' => \$number },
				alias        => 1,
			);
			
			$closure->();
			
			is($$number, 42, 'closure works');
			is($destroyed, 0, 'closed over variable still exists');
		}
		
		is($destroyed, 1, 'closed over variable destroyed once closure has been destroyed');
	};
}

{
	my @store;
	
	Eval::TypeTiny::_force_implementation( Eval::TypeTiny::IMPLEMENTATION_TIE );
	
	{
		package MyTie;
		use Tie::Scalar ();
		our @ISA = 'Tie::StdScalar';
		sub STORE {
			my $self = shift;
			push @store, $_[0];
			$self->SUPER::STORE(@_);
		}
		sub method_of_mine { 42 }
	}
	
	{
		package OtherTie;
		our @ISA = 'MyTie';
		sub method_of_mine { 666 }
	}
	
	tie(my($var), 'MyTie');
	
	$var = 1;
	
	subtest "tied variables can be closed over (even with tied alias implementation)" => sub {
	
		my $closure = eval_closure(
			source       => 'sub { $xxx = $_[0]; tied($xxx)->method_of_mine }',
			environment  => { '$xxx' => \$var },
			alias        => 1,
		);
		
		is($closure->(2), 42, 'can close over tied variables ... AUTOLOAD stuff');
		$closure->(3);
		
		my $nother_closure = eval_closure(
			source       => 'sub { tied($xxx)->can(@_) }',
			environment  => { '$xxx' => \$var },
			alias        => 1,
		);
		
		ok( $nother_closure->('method_of_mine'), '... can');
		ok(!$nother_closure->('your_method'), '... !can');

		is_deeply(
			\@store,
			[ 1 .. 3],
			'... tie still works',
		);
		
		tie($var, 'OtherTie');
		is($closure->(4), 666, '... can be retied');

		untie($var);
		my $e = exception { $closure->(5) };
		like($e, qr{^Can't call method "method_of_mine" on an undefined value}, '... can be untied');
	};
}

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

subtest "exception for syntax error" => sub {
	my $e3 = exception { eval_closure source => 'sub {' };
	ok( $e3->isa('Error::TypeTiny::Compilation'), 'proper exceptions thrown for compilation errors' );
	is( $e3->code, 'sub {', '$exception->code' );
	like( $e3->errstr, qr/Missing right curly/, '$exception->errstr' );
	is( ref $e3->context, 'HASH', '$exception->context' );
};

subtest "exception for syntax error (given arrayref)" => sub {
	my $e3 = exception { eval_closure source => ['sub {', ''] };
	ok( $e3->isa('Error::TypeTiny::Compilation'), 'proper exceptions thrown for compilation errors' );
	is( $e3->code, "sub {\n", '$exception->code' );
	like( $e3->errstr, qr/Missing right curly/, '$exception->errstr' );
	is( ref $e3->context, 'HASH', '$exception->context' );
};

subtest "exception for wrong reference type" => sub {
	my $e3 = exception { eval_closure source => 'sub {', environment => { '%foo' => [] } };
	ok($e3->isa('Error::TypeTiny'), 'exception was thrown');
	if (Eval::TypeTiny::_EXTENDED_TESTING) {
		like($e3->message, qr/^Expected a variable name and ref/, 'correct exception message');
	}
};

subtest "_pick_alternative" => sub {
	is Eval::TypeTiny::_pick_alternative( if => 1, 'foo' ) || 'bar', 'foo';
	is Eval::TypeTiny::_pick_alternative( if => 0, 'foo' ) || 'bar', 'bar';
};

done_testing;
