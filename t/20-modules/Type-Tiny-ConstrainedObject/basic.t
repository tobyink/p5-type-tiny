=pod

=encoding utf-8

=head1 PURPOSE

Check C<stringifies_to>, C<numifies_to>, and C<with_attribute_values>
work for L<Type::Tiny::Class>, L<Type::Tiny::Role>, and L<Type::Tiny::Duck>.

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
use Test::TypeTiny;

BEGIN {
	package Local::Class;
	use overload (
		q[""]    => sub { shift->as_string },
		q[0+]    => sub { shift->as_number },
		fallback => 1,
	);
	sub new {
		my $class = shift;
		my %args  = ref $_[0] ? %{$_[0]} : @_;
		bless \%args => $class;
	}
	sub AUTOLOAD {
		my $self = shift;
		our $AUTOLOAD;
		(my $method = $AUTOLOAD) =~ s/^.*:://;
		$self->{$method};
	}
	sub DOES {
		my $self = shift;
		my ($role) = @_;
		return 1 if $role eq 'Local::Role';
		$self->SUPER::DOES(@_);
	}
	sub can {
		my $self = shift;
		my ($method) = @_;
		my $r = $self->SUPER::can(@_);
		return $r if $r;
		if ($method !~ /^__/) {
			return sub { shift->{$method} };
		}
		$r;
	}
	sub DESTROY { }
};

use Type::Tiny::Class;
use Type::Tiny::Duck;
use Type::Tiny::Role;
use Types::Standard -types;

my $class_type = Type::Tiny::Class->new(class => 'Local::Class');
my $role_type  = Type::Tiny::Role->new(role => 'Local::Role');
my $duck_type  = Type::Tiny::Duck->new(methods => [qw/foo bar baz quux/]);

my @test_types = (
	[ $class_type, 'Class types...' ],
	[ $role_type,  'Role types...' ],
	[ $duck_type,  'Duck types...' ],
);

for my $tt (@test_types) {
	my ($base_type, $label) = @$tt;
	should_pass(
		Local::Class->new,
		$base_type,
		$label,
	);
	should_pass(
		Local::Class->new( as_string => '3', as_number => '3.1' ),
		$base_type->stringifies_to( Int ),
		'... stringifies_to (should pass)',
	);
	should_fail(
		Local::Class->new( as_string => '3.1', as_number => '3.1'  ),
		$base_type->stringifies_to( Int ),
		'... stringifies_to (should fail)',
	);
	should_pass(
		Local::Class->new( as_string => '3.1', as_number => '3' ),
		$base_type->numifies_to( Int ),
		'... numifies_to (should pass)',
	);
	should_fail(
		Local::Class->new( as_string => '3.1', as_number => '3.1'  ),
		$base_type->numifies_to( Int ),
		'... numifies_to (should fail)',
	);
	should_pass(
		Local::Class->new( foo => 1, bar => 'ABARA', baz => 3 ),
		$base_type->with_attribute_values( foo => Int, bar => qr/BAR/, baz => '$_%2' ),
		'... with_attribute_values (should pass)',
	);
	should_fail(
		Local::Class->new( foo => 'xyz', bar => 'ABARA', baz => 3 ),
		$base_type->with_attribute_values( foo => Int, bar => qr/BAR/, baz => '$_%2' ),
		'... with_attribute_values (should fail because of foo)',
	);
	should_fail(
		Local::Class->new( foo => 1, bar => 'XXX', baz => 3 ),
		$base_type->with_attribute_values( foo => Int, bar => qr/BAR/, baz => '$_%2' ),
		'... with_attribute_values (should fail because of bar)',
	);
	should_fail(
		Local::Class->new( foo => 1, bar => 'ABARA', baz => 2 ),
		$base_type->with_attribute_values( foo => Int, bar => qr/BAR/, baz => '$_%2' ),
		'... with_attribute_values (should fail because of baz)',
	);
}

done_testing();
