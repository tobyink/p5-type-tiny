=pod

=encoding utf-8

=head1 PURPOSE

Checks C<< of >> and C<< where >> import options works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;
use Test::TypeTiny;

BEGIN {
	package MyTypes;
	use Type::Library -base;
	$INC{'MyTypes.pm'} = __FILE__;
	
	__PACKAGE__->add_type(
		name                  => 'Ref',
		constraint            => sub { ref $_[0] },
		constraint_generator  => sub {
			my $x = shift;
			sub { ref $_[0] eq $x };
		},
	);
};

use MyTypes 'Ref';

should_pass([], Ref);
should_pass({}, Ref);
should_pass(sub {}, Ref);
should_fail(1, Ref);

should_pass([], Ref['ARRAY']);
should_fail({}, Ref['ARRAY']);
should_fail(sub {}, Ref['ARRAY']);
should_fail(1, Ref['ARRAY']);

should_pass({}, Ref['HASH']);
should_fail([], Ref['HASH']);
should_fail(sub {}, Ref['HASH']);
should_fail(1, Ref['HASH']);

use MyTypes Ref => { of => 'HASH', -as => 'HashRef' };

should_pass({}, HashRef);
should_fail([], HashRef);
should_fail(sub {}, HashRef);
should_fail(1, HashRef);

use MyTypes Ref => {
	where => sub { ref $_[0] eq 'ARRAY' or ref $_[0] eq 'HASH' },
	-as => 'ContainerRef',
};

should_pass({}, ContainerRef);
should_pass([], ContainerRef);
should_fail(sub {}, ContainerRef);
should_fail(1, ContainerRef);

use MyTypes is_Ref => { of => 'HASH', -as => 'is_HashRef' };

ok  is_HashRef({});
ok !is_HashRef([]);
ok !is_HashRef(sub {});
ok !is_HashRef(1);

BEGIN {
	package My::Types::Two;
	use Type::Library 1.011005
		-utils,
		-extends => [ 'Types::Standard' ],
		-declare => 'JSONCapable';
	
	declare JSONCapable,
		as Undef
		|  ScalarRef[ Enum[ 0..1 ] ]
		|  Num
		|  Str
		|  ArrayRef[ JSONCapable ]
		|  HashRef[ JSONCapable ]
		;
}

use My::Types::Two 'is_JSONCapable';

my $var = {
	foo => 1,
	bar => [ \0, "baz", [] ],
};

ok is_JSONCapable $var;

done_testing;

