=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> C<goto_next> option.

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
use Test::Fatal;

use Type::Params qw( compile_named_oo );
use Types::Standard -types;

{
	sub _foobar {
		$_ = my $arg = shift;
		wantarray
			? ( $arg->foo, $arg->bar )
			: [ $arg->foo, $arg->bar ];
	}
	
	my $sig;
	sub foobar {
		unshift @_, \&_foobar;
		goto( $sig ||= compile_named_oo { goto_next => 1 }, foo => Bool, bar => Int );
	}
}

subtest "goto_next => 1" => sub {
	
	is_deeply(
		[ foobar( foo => [], bar => 42 ) ],
		[ !!1, 42 ],
		'list context',
	);
	
	is_deeply(
		scalar( foobar( foo => [], bar => 42 ) ),
		[ !!1, 42 ],
		'scalar context',
	);
};

{
	sub _foobar2 {
		$_ = my $arg = shift;
		wantarray
			? ( $arg->foo, $arg->bar )
			: [ $arg->foo, $arg->bar ];
	}
	
	my $sig;
	sub foobar2 {
		goto( $sig ||= compile_named_oo { goto_next => \&_foobar2 }, foo => Bool, bar => Int );
	}
}

subtest "goto_next => CODEREF" => sub {
	
	is_deeply(
		[ foobar2( foo => [], bar => 42 ) ],
		[ !!1, 42 ],
		'list context',
	);
	
	is_deeply(
		scalar( foobar2( foo => [], bar => 42 ) ),
		[ !!1, 42 ],
		'scalar context',
	);
};

{
	my $_foobar3 = sub {
		$_ = my $arg = shift;
		wantarray
			? ( $arg->foo, $arg->bar )
			: [ $arg->foo, $arg->bar ];
	};
	
	*foobar3 = compile_named_oo { package => 'main', subname => 'foobar3', goto_next => $_foobar3 },
		foo => Bool, bar => Int;
}

subtest "goto_next => CODEREF (assign to glob)" => sub {
	
	is_deeply(
		[ foobar3( foo => [], bar => 42 ) ],
		[ !!1, 42 ],
		'list context',
	);
	
	is_deeply(
		scalar( foobar3( foo => [], bar => 42 ) ),
		[ !!1, 42 ],
		'scalar context',
	);
	
	is( $_->{'~~caller'}, 'main::foobar3', 'meta' );
};

done_testing;
