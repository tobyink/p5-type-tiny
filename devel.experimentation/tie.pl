use v5.14;

BEGIN {
	package Type::Tie::BASE;
	use Hash::FieldHash;
	Hash::FieldHash::fieldhash(my %constraint);
	sub _set_constraint { $constraint{$_[0]} = $_[1] }
	sub constraint      { $constraint{$_[0]} }
	sub assert_valid {
		my $self = shift;
		my $code = \&{$self->constraint};
		goto $code;
	}
}

BEGIN {
	package Type::Tie::SCALAR;
	use Tie::Scalar;
	use base qw( Tie::StdScalar Type::Tie::BASE );
	use Carp; $Carp::Internal{(__PACKAGE__)}++;
	sub TIESCALAR {
		my $class = shift;
		my $self  = $class->SUPER::TIESCALAR;
		$self->_set_constraint(@_);
		return $self;
	}
	sub STORE {
		my $self = shift;
		$self->assert_valid($_[0]);
		$self->SUPER::STORE(@_);
	}
}

BEGIN {
	package Type::Tie::ARRAY;
	use Tie::Array;
	use base qw( Tie::StdArray Type::Tie::BASE );
	use Carp; $Carp::Internal{(__PACKAGE__)}++;
	sub TIEARRAY {
		my $class = shift;
		my $self  = $class->SUPER::TIEARRAY;
		$self->_set_constraint(@_);
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
}

BEGIN {
	package Type::Tie::HASH;
	use Tie::Hash;
	use base qw( Tie::StdHash Type::Tie::BASE );
	use Carp; $Carp::Internal{(__PACKAGE__)}++;
	sub TIEHASH {
		my $class = shift;
		my $self  = $class->SUPER::TIEHASH;
		$self->_set_constraint(@_);
		return $self;
	}
	sub STORE {
		my $self = shift;
		$self->assert_valid($_[1]);
		$self->SUPER::STORE(@_);
	}
}

BEGIN {
	package Type::Tie;
	no thanks;
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