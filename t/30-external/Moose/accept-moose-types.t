=pod

=encoding utf-8

=head1 PURPOSE

Check that Moose type constraints can be passed into the Type::Tiny API where
a Type::Tiny constraint might usually be expected.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

Test is skipped if Moose 2.0000 is not available.

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
use Test::Requires { Moose => 2.0000 };
use Test::Fatal;

# Example from the manual
{
	package Person;
	
	use Moose;
	use Types::Standard qw( Str Int );
	use Type::Utils qw( declare as where inline_as coerce from );
	
	::isa_ok(
		Int,
		'Moose::Meta::TypeConstraint',
		'Int',
	);

	::isa_ok(
		Str,
		'Moose::Meta::TypeConstraint',
		'Str',
	);

	has name => (
		is      => "ro",
		isa     => Str,
	);
	
	my $PositiveInt = declare
		as        Int,
		where     {  $_ > 0  },
		inline_as { "$_ =~ /^0-9]\$/ and $_ > 0" };
	
	coerce $PositiveInt, from Int, q{ abs $_ };

	::isa_ok(
		$PositiveInt,
		'Type::Tiny',
		'$PositiveInt',
	);

	::isa_ok(
		$PositiveInt->parent,
		'Type::Tiny',
		'$PositiveInt->parent',
	);

	has age => (
		is      => "ro",
		isa     => $PositiveInt,
		coerce  => 1,
		writer  => "_set_age",
	);
	
	sub get_older {
		my $self = shift;
		my ($years) = @_;
		$PositiveInt->assert_valid($years);
		$self->_set_age($self->age + $years);
	}

}

done_testing;
