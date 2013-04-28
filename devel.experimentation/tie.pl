use strict;
use warnings;

BEGIN {
	package Type::Tie;
	$INC{"Type/Tie.pm"} = __FILE__;
	
	use Carp ();
	use Role::Tiny ();
	
	use base "Exporter::TypeTiny";
	our @EXPORT = qw(ttie);

	sub ttie (\[$@%]$;@)#>&%*/&<%\$[]^!@;@)
	{
		my ($ref, $type, @vals) = @_;
		
		if (ref($ref) eq "HASH")
		{
			tie(%$ref, "Type::Tie::HASH", $type);
			%$ref = @vals if @vals;
		}
		elsif (ref($ref) eq "ARRAY")
		{
			tie(@$ref, "Type::Tie::ARRAY", $type);
			@$ref = @vals if @vals;
		}
		else
		{
			tie($$ref, "Type::Tie::SCALAR", $type);
			$$ref = $vals[0] if @vals;
		}
		return $ref;
	}
	
	sub _make_role
	{
		my ($me, $type) = @_;
		
		my $rolename = sprintf("%s::Constraint%d", $me, $type->{uniq});
		return $rolename if $rolename->can('assert_valid');
		
		if ($type->can_be_inlined and not $type->has_message)
		{
			my $assertion = $type->inline_assert('$_[1]');
			$assertion =~ s/die/croak/;
			eval sprintf q{
				package %s;
				use Carp qw(croak);
				use Role::Tiny;
				sub assert_valid { %s };
				++$Carp::CarpInternal{+__PACKAGE__};
			}, $rolename, $assertion
			or die "Could not compile $rolename: $@";
		}
		else
		{
			eval sprintf q{
				package %s;
				use Role::Tiny;
				sub assert_valid { $type->assert_valid($_[1]) };
				++$Carp::CarpInternal{+__PACKAGE__};
			}, $rolename, $type->inline_assert('$_[0]')
			or die "Could not compile $rolename: $@";
		}
		
		return $rolename;
	}
	
	sub _apply_roles_to_object
	{
		my ($me, $obj, $type) = @_;
		my $role = $me->_make_role($type);
		"Role::Tiny"->apply_roles_to_object($obj, $role);
	}
}

BEGIN {
	package Type::Tie::SCALAR;
	use Tie::Scalar;
	use base qw( Tie::StdScalar );
	sub TIESCALAR {
		my $class = shift;
		my $self = $class->SUPER::TIESCALAR;
		"Type::Tie"->_apply_roles_to_object($self, @_);
		return $self;
	}
	sub STORE {
		my $self = shift;
		$self->assert_valid($_[0]);
		$self->SUPER::STORE(@_);
	}
	++$Carp::CarpInternal{+__PACKAGE__};
}

BEGIN {
	package Type::Tie::ARRAY;
	use Tie::Array;
	use base qw( Tie::StdArray );
	sub TIEARRAY {
		my $class = shift;
		my $self = $class->SUPER::TIEARRAY;
		"Type::Tie"->_apply_roles_to_object($self, @_);
		return $self;
	}
	sub STORE {
		my $self = shift;
		$self->assert_valid($_[1]);
		$self->SUPER::STORE(@_);
	}
	sub PUSH {
		my $self = shift;
		$self->assert_valid($_) for @_;
		$self->SUPER::PUSH(@_);
	}
	sub UNSHIFT {
		my $self = shift;
		$self->assert_valid($_) for @_;
		$self->SUPER::UNSHIFT(@_);
	}
	++$Carp::CarpInternal{+__PACKAGE__};
}

BEGIN {
	package Type::Tie::HASH;
	use Tie::Hash;
	use base qw( Tie::StdHash );
	sub TIEHASH {
		my $class = shift;
		my $self = $class->SUPER::TIEHASH;
		"Type::Tie"->_apply_roles_to_object($self, @_);
		return $self;
	}
	sub STORE {
		my $self = shift;
		$self->assert_valid($_[1]);
		$self->SUPER::STORE(@_);
	}
	++$Carp::CarpInternal{+__PACKAGE__};
}

{
	package Foo;
	
	use Data::Dumper;
	use Types::Standard -types;
	use Type::Utils;
	use Type::Tie;
	
	ttie my $v, Int, 0;
	$v++;
	print $v, $/;

	ttie my @V, Int;
	push @V, 1, 2, 3;
	print "@V", $/;
	
	# Here's a weakness
	ttie my $o, class_type { class => "Foo" };
	$o = bless [], "Foo";
	bless $o, "Bar"; # does not call STORE on tied object!
	print $o, $/;
	
	# Here's another weakness
	ttie my $a, (ArrayRef[Int]), [1, 2, 3];
	print Dumper($a);
	push @$a, 4.4; # does not call STORE on tied object!
	
	# Here's a workaround
	ttie my @b, Int, 1, 2, 3;
	my $b = \@b;   # Here's a ref to a tied array instead.
	print Dumper($b);
	push @$b, 4.4; # does call STORE!
}