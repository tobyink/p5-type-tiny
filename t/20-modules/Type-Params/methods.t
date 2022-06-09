=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> usage for method calls.

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

{
	package Silly::String;
	
	use Type::Params qw(Invocant compile);
	use Types::Standard qw(ClassName Object Str Int);
	
	my %chk;
	
	sub new {
		$chk{new} ||= compile(ClassName, Str);
		my ($class, $str) = $chk{new}->(@_);
		bless \$str, $class;
	}
	
	sub repeat {
		$chk{repeat} ||= compile(Object, Int);
		my ($self, $n) = $chk{repeat}->(@_);
		$self->get x $n;
	}
	
	sub get {
		$chk{get} ||= compile(Object);
		my ($self) = $chk{get}->(@_);
		$$self;
	}
	
	sub set {
		$chk{set} ||= compile(Invocant, Str);
		my ($proto, $str) = $chk{set}->(@_);
		Object->check($proto) ? ($$proto = $str) : $proto->new($str);
	}
}

is(
	exception {
		my $o = Silly::String->new("X");
		
		is($o->get, "X");
		is($o->repeat(4), "XXXX");
		
		$o->set("Y");
		is($o->repeat(4), "YYYY");
		
		my $p = Silly::String->set("Z");
		is($p->repeat(4), "ZZZZ");
	},
	undef,
	'clean operation',
);

like(
	exception { Silly::String::new() },
	qr{^Wrong number of parameters; got 0; expected 2},
	'exception calling new() with no args',
);

like(
	exception { Silly::String->new() },
	qr{^Wrong number of parameters; got 1; expected 2},
	'exception calling ->new() with no args',
);

like(
	exception { Silly::String::set() },
	qr{^Wrong number of parameters; got 0; expected 2},
	'exception calling set() with no args',
);

done_testing;
