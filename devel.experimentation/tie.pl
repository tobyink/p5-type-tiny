use v5.14;

BEGIN {
	package Type::Tie; no thanks;
	
	use Carp ();
	use Role::Tiny ();
	
	use base "Exporter::TypeTiny";
	our @EXPORT = qw(constrain);

	sub constrain (\[$@%]$)
	{
		my ($ref, $type) = @_;
		
		if (ref($ref) eq "HASH")
		{
			tie(%$ref, "Type::Tie::HASH", $type);
			return %$ref;
		}
		elsif (ref($ref) eq "ARRAY")
		{
			tie(@$ref, "Type::Tie::ARRAY", $type);
			return @$ref;
		}
		else
		{
			tie($$ref, "Type::Tie::SCALAR", $type);
			return $$ref;
		}
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
	
	use Types::Standard -types;
	use Type::Tie;
	
	constrain(my $v, Int);
	$v = 1;
	say $v;

	constrain(my @V, Int);
	push @V, 1, 2, 3.3;
	say "@V";
}