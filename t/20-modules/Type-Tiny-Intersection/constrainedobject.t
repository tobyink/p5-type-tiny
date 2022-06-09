=pod

=encoding utf-8

=head1 PURPOSE

Check C<stringifies_to>, C<numifies_to>, and C<with_attribute_values>
work for L<Type::Tiny::Intersection>.

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

my $intersect = $class_type & $role_type & $duck_type;
my $new = $intersect->with_attribute_values(foo => '%_<5');

my @new = @{ $new->type_constraints };

ok($new->[0] == $class_type->with_attribute_values(foo => '%_<5'));
ok($new->[1] == $role_type);
ok($new->[2] == $duck_type);

# nothing can pass this constraint but that doesn't matter
my $new2 = ((Int) & $class_type & (ArrayRef) & $role_type & $duck_type)
	->with_attribute_values(foo => '%_<5');
my @new2 = @{ $new2->type_constraints };

ok($new2->[0] == Int);
ok($new2->[1] == $class_type->with_attribute_values(foo => '%_<5'));
ok($new2->[2] == ArrayRef);
ok($new2->[3] == $role_type);
ok($new2->[4] == $duck_type);

my $new3 = ((Int) & $class_type & (ArrayRef) & $role_type & $duck_type)
	->stringifies_to( Enum['abc','xyz'] );
ok($new3->[0] == Int);
ok($new3->[1] == $class_type->stringifies_to( Enum['abc','xyz'] ));
ok($new3->[2] == ArrayRef);
ok($new3->[3] == $role_type);
ok($new3->[4] == $duck_type);

my $new4 = ((Int) & $class_type & (ArrayRef) & $role_type & $duck_type)
	->numifies_to( Enum[1..4] );
ok($new4->[0] == Int);
ok($new4->[1] == $class_type->numifies_to( Enum[1..4] ));
ok($new4->[2] == ArrayRef);
ok($new4->[3] == $role_type);
ok($new4->[4] == $duck_type);

my $working = ( (Ref['HASH']) & ($class_type) )->numifies_to(Enum[42]);
ok $working->can_be_inlined;
should_pass( 'Local::Class'->new( as_number => 42 ), $working );
should_fail( 'Local::Class'->new( as_number => 41 ), $working );

done_testing();
