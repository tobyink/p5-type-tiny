package Type::Standard;

use base "Type::Library";
use Type::Library::Util;

use Scalar::Util qw( blessed looks_like_number );

sub _is_class_loaded {
	return !!0 if ref $_[0];
	return !!0 if !defined $_[0];
	my $stash = do { no strict 'refs'; \%{"$_[0]\::"} };
	return !!1 if exists $stash->{'ISA'};
	return !!1 if exists $stash->{'VERSION'};
	foreach my $globref (values %$stash) {
		return !!1 if *{$globref}{CODE};
	}
	return !!0;
}

declare "Any";

declare "Item";

declare "Bool",
	as "Item",
	where { !defined $_ or $_ eq q() or $_ eq '0' or $_ eq '1' };

declare "Undef",
	as "Item",
	where { !defined $_ };

declare "Defined",
	as "Item",
	where { defined $_ };

declare "Value",
	as "Defined",
	where { not ref $_ };

declare "Str",
	as "Value",
	where { ref(\$_) eq 'SCALAR' or ref(\(my $val = $_)) eq 'SCALAR' };

declare "Num",
	as "Str",
	where { looks_like_number $_ };

declare "Int",
	as "Num",
	where { /\A-?[0-9]+\z/ };

declare "ClassName",
	as "Str",
	where { goto \&_is_class_loaded };

declare "RoleName",
	as "ClassName",
	where { not $_->can("new") };

declare "Ref",
	as "Defined",
	where { ref $_ };

declare "CodeRef",
	as "Ref",
	where { ref $_ eq "CODE" };

declare "RegexpRef",
	as "Ref",
	where { ref $_ eq "Regexp" };

declare "GlobRef",
	as "Ref",
	where { ref $_ eq "GLOB" };

declare "FileHandle",
	as "Ref",
	where {
		(ref($_) eq "GLOB" && Scalar::Util::openhandle($_))
		or (blessed($_) && $_->isa("IO::Handle"))
	};

declare "ArrayRef",
	as "Ref",
	where { ref $_ eq "ARRAY" },
	constraint_generator => sub
	{
		my $param = shift;
		return sub
		{
			my $array = shift;
			$param->check($_) || return for @$array;
			return !!1;
		};
	};

declare "HashRef",
	as "Ref",
	where { ref $_ eq "HASH" },
	constraint_generator => sub
	{
		my $param = shift;
		return sub
		{
			my $hash = shift;
			$param->check($_) || return for values %$hash;
			return !!1;
		};
	};	

declare "ScalarRef",
	as "Ref",
	where { ref $_ eq "SCALAR" or ref $_ eq "REF" },
	constraint_generator => sub
	{
		my $param = shift;
		return sub
		{
			my $ref = shift;
			$param->check($$ref) || return;
			return !!1;
		};
	};

declare "Object",
	as "Ref",
	where { blessed $_ };

declare "Maybe",
	as "Item",
	constraint_generator => sub
	{
		my $param = shift;
		return sub
		{
			my $value = shift;
			return !!1 unless defined $value;
			return $param->check($value);
		};
	};

# TODO: things from MooseX::Types::Structured

declare "Map",
	as "HashRef",
	where { ref $_ eq "HASH" },
	constraint_generator => sub
	{
		my ($keys, $values) = @_;
		return sub
		{
			my $hash = shift;
			$keys->check($_)   || return for keys %$hash;
			$values->check($_) || return for values %$hash;
			return !!1;
		};
	};

# TODO: inline_as

1;

