package Types::Standard;

use strict;
use warnings;

BEGIN {
	$Types::Standard::AUTHORITY = 'cpan:TOBYINK';
	$Types::Standard::VERSION   = '0.016';
}

use Type::Library -base;

our @EXPORT_OK = qw( slurpy );

use Scalar::Util qw( blessed looks_like_number );
use Types::TypeTiny ();

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

sub _croak ($;@) { require Type::Exception; goto \&Type::Exception::croak }

no warnings;

BEGIN { *STRICTNUM = $ENV{PERL_TYPES_STANDARD_STRICTNUM} ? sub(){!!1} : sub(){!!0} };

my $meta = __PACKAGE__->meta;

$meta->add_type({
	name       => "Any",
	_is_core   => 1,
	inlined    => sub { "!!1" },
});

my $_item = $meta->add_type({
	name       => "Item",
	_is_core   => 1,
	inlined    => sub { "!!1" },
});

$meta->add_type({
	name       => "Bool",
	_is_core   => 1,
	parent     => $_item,
	constraint => sub { !defined $_ or $_ eq q() or $_ eq '0' or $_ eq '1' },
	inlined    => sub { "!defined $_[1] or $_[1] eq q() or $_[1] eq '0' or $_[1] eq '1'" },
});

my $_undef = $meta->add_type({
	name       => "Undef",
	_is_core   => 1,
	parent     => $_item,
	constraint => sub { !defined $_ },
	inlined    => sub { "!defined($_[1])" },
});

my $_def = $meta->add_type({
	name       => "Defined",
	_is_core   => 1,
	parent     => $_item,
	constraint => sub { defined $_ },
	inlined    => sub { "defined($_[1])" },
});

my $_val = $meta->add_type({
	name       => "Value",
	_is_core   => 1,
	parent     => $_def,
	constraint => sub { not ref $_ },
	inlined    => sub { "defined($_[1]) and not ref($_[1])" },
});

my $_str = $meta->add_type({
	name       => "Str",
	_is_core   => 1,
	parent     => $_val,
	constraint => sub { ref(\$_) eq 'SCALAR' or ref(\(my $val = $_)) eq 'SCALAR' },
	inlined    => sub {
		"defined($_[1]) and do { ref(\\$_[1]) eq 'SCALAR' or ref(\\(my \$val = $_[1])) eq 'SCALAR' }"
	},
});

my $_laxnum = $meta->add_type({
	name       => "LaxNum",
	parent     => $_str,
	constraint => sub { looks_like_number $_ },
	inlined    => sub { "!ref($_[1]) && Scalar::Util::looks_like_number($_[1])" },
});

my $_strictnum = $meta->add_type({
	name       => "StrictNum",
	parent     => $_str,
	constraint => sub {
		my $val = $_;
		($val =~ /\A[+-]?[0-9]+\z/) ||
		( $val =~ /\A(?:[+-]?)                #matches optional +- in the beginning
		(?=[0-9]|\.[0-9])                     #matches previous +- only if there is something like 3 or .3
		[0-9]*                                #matches 0-9 zero or more times
		(?:\.[0-9]+)?                         #matches optional .89 or nothing
		(?:[Ee](?:[+-]?[0-9]+))?              #matches E1 or e1 or e-1 or e+1 etc
		\z/x );
	},
	inlined    => sub {
		'my $val = '.$_[1].';'.
		Value()->inline_check('$val')
		.' && ( $val =~ /\A[+-]?[0-9]+\z/ || '
		. '$val =~ /\A(?:[+-]?)              # matches optional +- in the beginning
			(?=[0-9]|\.[0-9])                 # matches previous +- only if there is something like 3 or .3
			[0-9]*                            # matches 0-9 zero or more times
			(?:\.[0-9]+)?                     # matches optional .89 or nothing
			(?:[Ee](?:[+-]?[0-9]+))?          # matches E1 or e1 or e-1 or e+1 etc
		\z/x ); '
	},
});

my $_num = $meta->add_type({
	name       => "Num",
	_is_core   => 1,
	parent     => (STRICTNUM ? $_strictnum : $_laxnum),
});

$meta->add_type({
	name       => "Int",
	_is_core   => 1,
	parent     => $_num,
	constraint => sub { /\A-?[0-9]+\z/ },
	inlined    => sub { "defined $_[1] and $_[1] =~ /\\A-?[0-9]+\\z/" },
});

my $_classn = $meta->add_type({
	name       => "ClassName",
	_is_core   => 1,
	parent     => $_str,
	constraint => sub { goto \&_is_class_loaded },
	inlined    => sub { "Types::Standard::_is_class_loaded($_[1])" },
});

$meta->add_type({
	name       => "RoleName",
	parent     => $_classn,
	constraint => sub { not $_->can("new") },
	inlined    => sub { "Types::Standard::_is_class_loaded($_[1]) and not $_[1]\->can('new')" },
});

my $_ref = $meta->add_type({
	name       => "Ref",
	_is_core   => 1,
	parent     => $_def,
	constraint => sub { ref $_ },
	inlined    => sub { "!!ref($_[1])" },
	constraint_generator => sub
	{
		my $reftype = shift;
		Types::TypeTiny::StringLike->check($reftype)
			or _croak("Parameter to Ref[`a] expected to be string; got $reftype");
		
		$reftype = "$reftype";
		return sub {
			ref($_[0]) and Scalar::Util::reftype($_[0]) eq $reftype;
		}
	},
	inline_generator => sub
	{
		my $reftype = shift;
		return sub {
			my $v = $_[1];
			"ref($v) and Scalar::Util::reftype($v) eq q($reftype)";
		};
	},
	deep_explanation => sub {
		require B;
		my ($type, $value, $varname) = @_;
		my $param = $type->parameters->[0];
		return if $type->check($value);
		my $reftype = Scalar::Util::reftype($value);
		return [
			sprintf('"%s" constrains reftype(%s) to be equal to %s', $type, $varname, B::perlstring($param)),
			sprintf('reftype(%s) is %s', $varname, defined($reftype) ? B::perlstring($reftype) : "undef"),
		];
	},
});

$meta->add_type({
	name       => "CodeRef",
	_is_core   => 1,
	parent     => $_ref,
	constraint => sub { ref $_ eq "CODE" },
	inlined    => sub { "ref($_[1]) eq 'CODE'" },
});

$meta->add_type({
	name       => "RegexpRef",
	_is_core   => 1,
	parent     => $_ref,
	constraint => sub { ref $_ eq "Regexp" },
	inlined    => sub { "ref($_[1]) eq 'Regexp'" },
});

$meta->add_type({
	name       => "GlobRef",
	_is_core   => 1,
	parent     => $_ref,
	constraint => sub { ref $_ eq "GLOB" },
	inlined    => sub { "ref($_[1]) eq 'GLOB'" },
});

$meta->add_type({
	name       => "FileHandle",
	_is_core   => 1,
	parent     => $_ref,
	constraint => sub {
		(ref($_) eq "GLOB" && Scalar::Util::openhandle($_))
		or (blessed($_) && $_->isa("IO::Handle"))
	},
	inlined    => sub {
		"(ref($_[1]) eq \"GLOB\" && Scalar::Util::openhandle($_[1])) ".
		"or (Scalar::Util::blessed($_[1]) && $_[1]\->isa(\"IO::Handle\"))"
	},
});

my $_arr = $meta->add_type({
	name       => "ArrayRef",
	_is_core   => 1,
	parent     => $_ref,
	constraint => sub { ref $_ eq "ARRAY" },
	inlined    => sub { "ref($_[1]) eq 'ARRAY'" },
	constraint_generator => sub
	{
		my $param = Types::TypeTiny::to_TypeTiny(shift);
		Types::TypeTiny::TypeTiny->check($param)
			or _croak("Parameter to ArrayRef[`a] expected to be a type constraint; got $param");
		
		return sub
		{
			my $array = shift;
			$param->check($_) || return for @$array;
			return !!1;
		};
	},
	inline_generator => sub {
		my $param = shift;
		return unless $param->can_be_inlined;
		my $param_check = $param->inline_check('$i');
		return sub {
			my $v = $_[1];
			"ref($v) eq 'ARRAY' and do { "
			.  "my \$ok = 1; "
			.  "for my \$i (\@{$v}) { "
			.    "\$ok = 0 && last unless $param_check "
			.  "}; "
			.  "\$ok "
			."}"
		};
	},
	deep_explanation => sub {
		my ($type, $value, $varname) = @_;
		my $param = $type->parameters->[0];
		
		for my $i (0 .. $#$value)
		{
			my $item = $value->[$i];
			next if $param->check($item);
			require Type::Exception::Assertion;
			return [
				sprintf('"%s" constrains each value in the array with "%s"', $type, $param),
				@{
					"Type::Exception::Assertion"->_explain(
						$param,
						$item,
						sprintf('%s->[%d]', $varname, $i),
					)
				},
			]
		}
		
		return;
	},
});

my $_hash = $meta->add_type({
	name       => "HashRef",
	_is_core   => 1,
	parent     => $_ref,
	constraint => sub { ref $_ eq "HASH" },
	inlined    => sub { "ref($_[1]) eq 'HASH'" },
	constraint_generator => sub
	{
		my $param = Types::TypeTiny::to_TypeTiny(shift);
		Types::TypeTiny::TypeTiny->check($param)
			or _croak("Parameter to HashRef[`a] expected to be a type constraint; got $param");
		
		return sub
		{
			my $hash = shift;
			$param->check($_) || return for values %$hash;
			return !!1;
		};
	},
	inline_generator => sub {
		my $param = shift;
		return unless $param->can_be_inlined;
		my $param_check = $param->inline_check('$i');
		return sub {
			my $v = $_[1];
			"ref($v) eq 'HASH' and do { "
			.  "my \$ok = 1; "
			.  "for my \$i (values \%{$v}) { "
			.    "\$ok = 0 && last unless $param_check "
			.  "}; "
			.  "\$ok "
			."}"
		};
	},
	deep_explanation => sub {
		require B;
		my ($type, $value, $varname) = @_;
		my $param = $type->parameters->[0];
		
		for my $k (sort keys %$value)
		{
			my $item = $value->{$k};
			next if $param->check($item);
			require Type::Exception::Assertion;
			return [
				sprintf('"%s" constrains each value in the hash with "%s"', $type, $param),
				@{
					"Type::Exception::Assertion"->_explain(
						$param,
						$item,
						sprintf('%s->{%s}', $varname, B::perlstring($k)),
					)
				}
			];
		}
		
		return;
	},
});

$meta->add_type({
	name       => "ScalarRef",
	_is_core   => 1,
	parent     => $_ref,
	constraint => sub { ref $_ eq "SCALAR" or ref $_ eq "REF" },
	inlined    => sub { "ref($_[1]) eq 'SCALAR' or ref($_[1]) eq 'REF'" },
	constraint_generator => sub
	{
		my $param = Types::TypeTiny::to_TypeTiny(shift);
		Types::TypeTiny::TypeTiny->check($param)
			or _croak("Parameter to ScalarRef[`a] expected to be a type constraint; got $param");
		
		return sub
		{
			my $ref = shift;
			$param->check($$ref) || return;
			return !!1;
		};
	},
	inline_generator => sub {
		my $param = shift;
		return unless $param->can_be_inlined;
		return sub {
			my $v = $_[1];
			my $param_check = $param->inline_check("\${$v}");
			"(ref($v) eq 'SCALAR' or ref($v) eq 'REF') and $param_check";
		};
	},
	deep_explanation => sub {
		my ($type, $value, $varname) = @_;
		my $param = $type->parameters->[0];
		
		for my $item ($$value)
		{
			next if $param->check($item);
			require Type::Exception::Assertion;
			return [
				sprintf('"%s" constrains the referenced scalar value with "%s"', $type, $param),
				@{
					"Type::Exception::Assertion"->_explain(
						$param,
						$item,
						sprintf('${%s}', $varname),
					)
				}
			];
		}
		
		return;
	},
});

my $_obj = $meta->add_type({
	name       => "Object",
	_is_core   => 1,
	parent     => $_ref,
	constraint => sub { blessed $_ },
	inlined    => sub { "Scalar::Util::blessed($_[1])" },
});

$meta->add_type({
	name       => "Maybe",
	_is_core   => 1,
	parent     => $_item,
	constraint_generator => sub
	{
		my $param = Types::TypeTiny::to_TypeTiny(shift);
		Types::TypeTiny::TypeTiny->check($param)
			or _croak("Parameter to Maybe[`a] expected to be a type constraint; got $param");
		
		return sub
		{
			my $value = shift;
			return !!1 unless defined $value;
			return $param->check($value);
		};
	},
	inline_generator => sub {
		my $param = shift;
		return unless $param->can_be_inlined;
		return sub {
			my $v = $_[1];
			my $param_check = $param->inline_check($v);
			"!defined($v) or $param_check";
		};
	},
	deep_explanation => sub {
		my ($type, $value, $varname) = @_;
		my $param = $type->parameters->[0];
		
		return [
			sprintf('%s is defined', Type::Tiny::_dd($value)),
			sprintf('"%s" constrains the value with "%s" if it is defined', $type, $param),
			@{
				"Type::Exception::Assertion"->_explain(
					$param,
					$value,
					$varname,
				)
			}
		];
	},
});

$meta->add_type({
	name       => "Map",
	parent     => $_hash,
	constraint_generator => sub
	{
		my ($keys, $values) = map Types::TypeTiny::to_TypeTiny($_), @_;
		Types::TypeTiny::TypeTiny->check($keys)
			or _croak("First parameter to Map[`k,`v] expected to be a type constraint; got $keys");
		Types::TypeTiny::TypeTiny->check($values)
			or _croak("Second parameter to Map[`k,`v] expected to be a type constraint; got $values");
		
		return sub
		{
			my $hash = shift;
			$keys->check($_)   || return for keys %$hash;
			$values->check($_) || return for values %$hash;
			return !!1;
		};
	},
	inline_generator => sub {
		my ($k, $v) = @_;
		return unless $k->can_be_inlined && $v->can_be_inlined;
		my $k_check = $k->inline_check('$k');
		my $v_check = $v->inline_check('$v');
		return sub {
			my $h = $_[1];
			"ref($h) eq 'HASH' and do { "
			.  "my \$ok = 1; "
			.  "for my \$v (values \%{$h}) { "
			.    "\$ok = 0 && last unless $v_check "
			.  "}; "
			.  "for my \$k (keys \%{$h}) { "
			.    "\$ok = 0 && last unless $k_check "
			.  "}; "
			.  "\$ok "
			."}"
		};
	},
	deep_explanation => sub {
		require B;
		my ($type, $value, $varname) = @_;
		my ($kparam, $vparam) = @{ $type->parameters };
		
		for my $k (sort keys %$value)
		{
			unless ($kparam->check($k))
			{
				require Type::Exception::Assertion;
				return [
					sprintf('"%s" constrains each key in the hash with "%s"', $type, $kparam),
					@{
						"Type::Exception::Assertion"->_explain(
							$kparam,
							$k,
							sprintf('key %s->{%s}', $varname, B::perlstring($k)),
						)
					}
				];
			}
			
			unless ($vparam->check($value->{$k}))
			{
				require Type::Exception::Assertion;
				return [
					sprintf('"%s" constrains each value in the hash with "%s"', $type, $vparam),
					@{
						"Type::Exception::Assertion"->_explain(
							$vparam,
							$value->{$k},
							sprintf('%s->{%s}', $varname, B::perlstring($k)),
						)
					}
				];
			}
		}
		
		return;
	},
});

$meta->add_type({
	name       => "Optional",
	parent     => $_item,
	constraint_generator => sub
	{
		my $param = Types::TypeTiny::to_TypeTiny(shift);
		Types::TypeTiny::TypeTiny->check($param)
			or _croak("Parameter to Optional[`a] expected to be a type constraint; got $param");
		
		sub { exists($_[0]) ? $param->check($_[0]) : !!1 }
	},
	inline_generator => sub {
		my $param = shift;
		return unless $param->can_be_inlined;
		return sub {
			my $v = $_[1];
			my $param_check = $param->inline_check($v);
			"!exists($v) or $param_check";
		};
	},
	deep_explanation => sub {
		my ($type, $value, $varname) = @_;
		my $param = $type->parameters->[0];
		
		return [
			sprintf('%s exists', $varname),
			sprintf('"%s" constrains %s with "%s" if it exists', $type, $varname, $param),
			@{
				"Type::Exception::Assertion"->_explain(
					$param,
					$value,
					$varname,
				)
			}
		];
	},
});

sub slurpy {
	my $t = shift;
	wantarray ? (+{ slurpy => $t }, @_) : +{ slurpy => $t };
}

$meta->add_type({
	name       => "Tuple",
	parent     => $_arr,
	name_generator => sub
	{
		my ($s, @a) = @_;
		sprintf('%s[%s]', $s, join q[,], map { ref($_) eq "HASH" ? sprintf("slurpy %s", $_->{slurpy}) : $_ } @a);
	},
	constraint_generator => sub
	{
		my @constraints = @_;
		my $slurpy;
		if (exists $constraints[-1] and ref $constraints[-1] eq "HASH")
		{
			$slurpy = Types::TypeTiny::to_TypeTiny(pop(@constraints)->{slurpy});
			Types::TypeTiny::TypeTiny->check($slurpy)
				or _croak("Slurpy parameter to Tuple[...] expected to be a type constraint; got $slurpy");
		}
		
		@constraints = map Types::TypeTiny::to_TypeTiny($_), @constraints;
		for (@constraints)
		{
			Types::TypeTiny::TypeTiny->check($_)
				or _croak("Parameters to Tuple[...] expected to be type constraints; got $_");
		}
			
		return sub
		{
			my $value = $_[0];
			if ($#constraints < $#$value)
			{
				defined($slurpy) && $slurpy->check(
					$slurpy->is_a_type_of(HashRef())
						? +{@$value[$#constraints+1 .. $#$value]}
						: +[@$value[$#constraints+1 .. $#$value]]
				) or return;
			}
			for my $i (0 .. $#constraints)
			{
				$constraints[$i]->check(exists $value->[$i] ? $value->[$i] : ()) or return;
			}
			return !!1;
		};
	},
	inline_generator => sub
	{
		my @constraints = @_;
		my $slurpy;
		if (exists $constraints[-1] and ref $constraints[-1] eq "HASH")
		{
			$slurpy = pop(@constraints)->{slurpy};
		}
		
		return if grep { not $_->can_be_inlined } @constraints;
		return if defined $slurpy && !$slurpy->can_be_inlined;
		
		my $tmpl = defined($slurpy) && $slurpy->is_a_type_of(HashRef())
			? "do { my \$tmp = +{\@{%s}[%d..\$#{%s}]}; %s }"
			: "do { my \$tmp = +[\@{%s}[%d..\$#{%s}]]; %s }";
		
		return sub
		{
			my $v = $_[1];
			join " and ",
				"ref($v) eq 'ARRAY'",
				($slurpy
					? sprintf($tmpl, $v, $#constraints+1, $v, $slurpy->inline_check('$tmp'))
					: sprintf("\@{$v} <= %d", scalar @constraints)
				),
				map { $constraints[$_]->inline_check("$v\->[$_]") } 0 .. $#constraints;
		};
	},
	deep_explanation => sub {
		my ($type, $value, $varname) = @_;
		
		my @constraints = @{ $type->parameters };
		my $slurpy;
		if (exists $constraints[-1] and ref $constraints[-1] eq "HASH")
		{
			$slurpy = Types::TypeTiny::to_TypeTiny(pop(@constraints)->{slurpy});
		}
		@constraints = map Types::TypeTiny::to_TypeTiny($_), @constraints;
		
		if ($#constraints < $#$value and not $slurpy)
		{
			return [
				sprintf('"%s" expects at most %d values in the array', $type, $#constraints),
				sprintf('%d values found; too many', $#$value),
			];
		}
		
		for my $i (0 .. $#constraints)
		{
			next if $constraints[$i]->parent == Optional() && $i > $#$value;
			next if $constraints[$i]->check($value->[$i]);
			
			return [
				sprintf('"%s" constrains value at index %d of array with "%s"', $type, $i, $constraints[$i]),
				@{
					"Type::Exception::Assertion"->_explain(
						$constraints[$i],
						$value->[$i],
						sprintf('%s->[%s]', $varname, $i),
					)
				}
			];
		}
		
		if (defined($slurpy))
		{
			my $tmp = $slurpy->is_a_type_of(HashRef())
				? +{@$value[$#constraints+1 .. $#$value]}
				: +[@$value[$#constraints+1 .. $#$value]];
			$slurpy->check($tmp) or return [
				sprintf(
					'Array elements from index %d are slurped into a %s which is constrained with "%s"',
					$#constraints+1,
					$slurpy->is_a_type_of(HashRef()) ? 'hashref' : 'arrayref',
					$slurpy,
				),
				@{
					"Type::Exception::Assertion"->_explain(
						$slurpy,
						$tmp,
						'$SLURPY',
					)
				},
			];
		}
		
		return;
	},
});

$meta->add_type({
	name       => "Dict",
	parent     => $_hash,
	name_generator => sub
	{
		my ($s, %a) = @_;
		sprintf('%s[%s]', $s, join q[,], map sprintf("%s=>%s", $_, $a{$_}), sort keys %a);
	},
	constraint_generator => sub
	{
		my %constraints = @_;
		
		while (my ($k, $v) = each %constraints)
		{
			$constraints{$k} = Types::TypeTiny::to_TypeTiny($v);
			Types::TypeTiny::TypeTiny->check($v)
				or _croak("Parameter to Dict[`a] for key '$k' expected to be a type constraint; got $v");
		}
		
		return sub
		{
			my $value = $_[0];
			exists ($constraints{$_}) || return for sort keys %$value;
			$constraints{$_}->check(exists $value->{$_} ? $value->{$_} : ()) || return for sort keys %constraints;
			return !!1;
		};
	},
	inline_generator => sub
	{
		# We can only inline a parameterized Dict if all the
		# constraints inside can be inlined.
		my %constraints = @_;
		for my $c (values %constraints)
		{
			next if $c->can_be_inlined;
			return;
		}
		my $regexp = join "|", map quotemeta, sort keys %constraints;
		return sub
		{
			require B;
			my $h = $_[1];
			join " and ",
				"ref($h) eq 'HASH'",
				"not(grep !/^($regexp)\$/, keys \%{$h})",
				map {
					my $k = B::perlstring($_);
					$constraints{$_}->inline_check("$h\->{$k}");
				}
				sort keys %constraints;
		}
	},
	deep_explanation => sub {
		require B;
		my ($type, $value, $varname) = @_;
		my %constraints = @{ $type->parameters };
		
		for my $k (sort keys %$value)
		{
			return [
				sprintf('"%s" does not allow key %s to appear in hash', $type, B::perlstring($k))
			] unless exists $constraints{$k};
		}
		
		for my $k (sort keys %constraints)
		{
			next if $constraints{$k}->parent == Optional() && !exists $value->{$k};
			next if $constraints{$k}->check($value->{$k});
			
			return [
				sprintf('"%s" requires key %s to appear in hash', $type, B::perlstring($k))
			] unless exists $value->{$k};
			
			return [
				sprintf('"%s" constrains value at key %s of hash with "%s"', $type, B::perlstring($k), $constraints{$k}),
				@{
					"Type::Exception::Assertion"->_explain(
						$constraints{$k},
						$value->{$k},
						sprintf('%s->{%s}', $varname, B::perlstring($k)),
					)
				}
			];
		}
		
		return;
	},
});

use overload ();
$meta->add_type({
	name       => "Overload",
	parent     => $_obj,
	constraint => sub { overload::Overloaded($_) },
	inlined    => sub { "Scalar::Util::blessed($_[1]) and overload::Overloaded($_[1])" },
	constraint_generator => sub
	{
		my @operations = map {
			Types::TypeTiny::StringLike->check($_)
				? "$_"
				: _croak("Parameters to Overload[`a] expected to be a strings; got $_");
		} @_;
		
		return sub {
			my $value = shift;
			for my $op (@operations) {
				return unless overload::Method($value, $op);
			}
			return !!1;
		}
	},
	inline_generator => sub {
		my @operations = @_;
		return sub {
			my $v = $_[1];
			join " and ",
				"Scalar::Util::blessed($v)",
				map "overload::Method($v, q[$_])", @operations;
		};
	},
});

our %_StrMatch;
$meta->add_type({
	name       => "StrMatch",
	parent     => $_str,
	constraint_generator => sub
	{
		my ($regexp, $checker) = @_;
		
		ref($regexp) eq 'Regexp'
			or _croak("First parameter to StrMatch[`a] expected to be a Regexp; got $regexp");
		
		if (@_ > 1)
		{
			$checker = Types::TypeTiny::to_TypeTiny($checker);
			Types::TypeTiny::TypeTiny->check($checker)
				or _croak("Second parameter to StrMatch[`a] expected to be a type constraint; got $checker")
		}
		
		$checker
			? sub {
				my $value = shift;
				return if ref($value);
				my @m = ($value =~ $regexp);
				$checker->check(\@m);
			}
			: sub {
				my $value = shift;
				!ref($value) and $value =~ $regexp;
			}
		;
	},
	inline_generator => sub
	{
		require B;
		my ($regexp, $checker) = @_;
		my $regexp_string = "$regexp";
		$_StrMatch{$regexp_string} = $regexp;
		if ($checker)
		{
			return unless $checker->can_be_inlined;
			return sub
			{
				my $v = $_[1];
				sprintf
					"!ref($v) and do { my \$m = [$v =~ \$Types::Standard::_StrMatch{%s}]; %s }",
					B::perlstring($regexp_string),
					$checker->inline_check('$m'),
				;
			};
		}
		else
		{
			return sub
			{
				my $v = $_[1];
				sprintf
					"!ref($v) and $v =~ \$Types::Standard::_StrMatch{%s}",
					B::perlstring($regexp_string),
				;
			};
		}
	},
});

$meta->add_type({
	name       => "OptList",
	parent     => $_arr->parameterize($_arr),
	constraint => sub {
		for my $inner (@$_) {
			return unless @$inner == 2;
			return unless is_Str($inner->[0]);
		}
		return !!1;
	},
	inlined     => sub {
		my ($self, $var) = @_;
		my $Str_check = __PACKAGE__->meta->get_type("Str")->inline_check('$inner->[0]');
		my @code = 'do { my $ok = 1; ';
		push @code,   sprintf('for my $inner (@{%s}) { no warnings; ', $var);
		push @code,     '($ok=0) && last unless @$inner == 2; ';
		push @code,     sprintf('($ok=0) && last unless (%s); ', $Str_check);
		push @code,   '} ';
		push @code, '$ok }';
		my $r = sprintf(
			'%s and %s',
			$self->parent->inline_check($var),
			join(q( ), @code),
		);
	},
});

$meta->add_type({
	name       => "Tied",
	parent     => $_ref,
	constraint => sub {
		!!tied(Scalar::Util::reftype($_) eq 'HASH' ?  %{$_} : Scalar::Util::reftype($_) eq 'ARRAY' ?  @{$_} :  ${$_})
	},
	inlined    => sub {
		my ($self, $var) = @_;
		$self->parent->inline_check($var)
		. " and !!tied(Scalar::Util::reftype($var) eq 'HASH' ? \%{$var} : Scalar::Util::reftype($var) eq 'ARRAY' ? \@{$var} : \${$var})"
	},
	name_generator => sub
	{
		my $self  = shift;
		my $param = Types::TypeTiny::to_TypeTiny(shift);
		unless (Types::TypeTiny::TypeTiny->check($param))
		{
			Types::TypeTiny::StringLike->check($param)
				or _croak("Parameter to Tied[`a] expected to be a class name; got $param");
			require B;
			return sprintf("%s[%s]", $self, B::perlstring($param));
		}
		return sprintf("%s[%s]", $self, $param);
	},
	constraint_generator => sub
	{
		my $param = Types::TypeTiny::to_TypeTiny(shift);
		unless (Types::TypeTiny::TypeTiny->check($param))
		{
			Types::TypeTiny::StringLike->check($param)
				or _croak("Parameter to Tied[`a] expected to be a class name; got $param");
			require Type::Tiny::Class;
			$param = "Type::Tiny::Class"->new(class => "$param");
		}
		
		my $check = $param->compiled_check;
		return sub {
			$check->(tied(Scalar::Util::reftype($_) eq 'HASH' ?  %{$_} : Scalar::Util::reftype($_) eq 'ARRAY' ?  @{$_} :  ${$_}));
		};
	},
	inline_generator => sub {
		my $param = Types::TypeTiny::to_TypeTiny(shift);
		unless (Types::TypeTiny::TypeTiny->check($param))
		{
			Types::TypeTiny::StringLike->check($param)
				or _croak("Parameter to Tied[`a] expected to be a class name; got $param");
			require Type::Tiny::Class;
			$param = "Type::Tiny::Class"->new(class => "$param");
		}
		return unless $param->can_be_inlined;
		
		return sub {
			require B;
			my $var = $_[1];
			sprintf(
				"%s and do { my \$TIED = tied(Scalar::Util::reftype($var) eq 'HASH' ? \%{$var} : Scalar::Util::reftype($var) eq 'ARRAY' ? \@{$var} : \${$var}); %s }",
				Ref()->inline_check($var),
				$param->inline_check('$TIED')
			);
		};
	},
});

$meta->add_type({
	name       => "InstanceOf",
	parent     => $_obj,
	constraint_generator => sub {
		require Type::Tiny::Class;
		my @classes = map {
			Types::TypeTiny::TypeTiny->check($_)
				? $_
				: "Type::Tiny::Class"->new(class => $_, display_name => sprintf('InstanceOf[%s]', B::perlstring($_)))
		} @_;
		return $classes[0] if @classes == 1;
		
		require B;
		require Type::Tiny::Union;
		return "Type::Tiny::Union"->new(
			type_constraints => \@classes,
			display_name     => sprintf('InstanceOf[%s]', join q[,], map B::perlstring($_->class), @classes),
		);
	},
});

$meta->add_type({
	name       => "ConsumerOf",
	parent     => $_obj,
	constraint_generator => sub {
		require B;
		require Type::Tiny::Role;
		my @roles = map {
			Types::TypeTiny::TypeTiny->check($_)
				? $_
				: "Type::Tiny::Role"->new(role => $_, display_name => sprintf('ConsumerOf[%s]', B::perlstring($_)))
		} @_;
		return $roles[0] if @roles == 1;
		
		require Type::Tiny::Intersection;
		return "Type::Tiny::Intersection"->new(
			type_constraints => \@roles,
			display_name     => sprintf('ConsumerOf[%s]', join q[,], map B::perlstring($_->role), @roles),
		);
	},
});

$meta->add_type({
	name       => "HasMethods",
	parent     => $_obj,
	constraint_generator => sub {
		require B;
		require Type::Tiny::Duck;
		return "Type::Tiny::Duck"->new(
			methods      => \@_,
			display_name => sprintf('HasMethods[%s]', join q[,], map B::perlstring($_), @_),
		);
	},
});

$meta->add_type({
	name       => "Enum",
	parent     => $_str,
	constraint_generator => sub {
		require B;
		require Type::Tiny::Enum;
		return "Type::Tiny::Enum"->new(
			values       => \@_,
			display_name => sprintf('Enum[%s]', join q[,], map B::perlstring($_), @_),
		);
	},
});

$meta->add_coercion({
	name               => "MkOpt",
	type_constraint    => $meta->get_type("OptList"),
	type_coercion_map  => [
		$_arr,    q{ Exporter::TypeTiny::mkopt($_) },
		$_hash,   q{ Exporter::TypeTiny::mkopt($_) },
		$_undef,  q{ [] },
	],
});

$meta->add_coercion({
	name               => "Join",
	type_constraint    => $_str,
	coercion_generator => sub {
		my ($self, $target, $sep) = @_;
		Types::TypeTiny::StringLike->check($sep)
			or _croak("Parameter to Join[`a] expected to be a string; got $sep");
		require B;
		$sep = B::perlstring($sep);
		return (ArrayRef(), qq{ join($sep, \@\$_) });
	},
});

$meta->add_coercion({
	name               => "Split",
	type_constraint    => $_arr,
	coercion_generator => sub {
		my ($self, $target, $re) = @_;
		ref($re) eq q(Regexp)
			or _croak("Parameter to Split[`a] expected to be a regular expresssion; got $re");
		my $regexp_string = "$re";
		$regexp_string =~ s/\\\//\\\\\//g; # toothpicks
		return (Str(), qq{ [split /$regexp_string/, \$_] });
	},
});

#### Deep coercion stuff...

sub Stringable (&)
{
	package #private
	Types::Standard::_Stringable;
	use overload q[""] => sub { $_[0]{text} ||= $_[0]{code}->() }, fallback => 1;
	bless +{ code => $_[0] };
}

my $lib = "Types::Standard"->meta;

$lib->get_type("ArrayRef")->{coercion_generator} = sub
{
	my ($parent, $child, $param) = @_;
	return unless $param->has_coercion;
	
	my $coercable_item = $param->coercion->_source_type_union;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	if ($param->coercion->can_be_inlined and $coercable_item->can_be_inlined)
	{
		$C->add_type_coercions($parent => Stringable {
			my @code;
			push @code, 'do { my ($orig, $return_orig, @new) = ($_, 0);';
			push @code,    'for (@$orig) {';
			push @code, sprintf('$return_orig++ && last unless (%s);', $coercable_item->inline_check('$_'));
			push @code, sprintf('push @new, (%s);', $param->coercion->inline_coercion('$_'));
			push @code,    '}';
			push @code,    '$return_orig ? $orig : \\@new';
			push @code, '}';
			"@code";
		});
	}
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my @new;
				for my $item (@$value)
				{
					return $value unless $coercable_item->check($item);
					push @new, $param->coerce($item);
				}
				return \@new;
			},
		);
	}
	
	return $C;
};

$lib->get_type("HashRef")->{coercion_generator} = sub
{
	my ($parent, $child, $param) = @_;
	return unless $param->has_coercion;
	
	my $coercable_item = $param->coercion->_source_type_union;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	if ($param->coercion->can_be_inlined and $coercable_item->can_be_inlined)
	{
		$C->add_type_coercions($parent => Stringable {
			my @code;
			push @code, 'do { my ($orig, $return_orig, %new) = ($_, 0);';
			push @code,    'for (keys %$orig) {';
			push @code, sprintf('$return_orig++ && last unless (%s);', $coercable_item->inline_check('$orig->{$_}'));
			push @code, sprintf('$new{$_} = (%s);', $param->coercion->inline_coercion('$orig->{$_}'));
			push @code,    '}';
			push @code,    '$return_orig ? $orig : \\%new';
			push @code, '}';
			"@code";
		});
	}
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my %new;
				for my $k (keys %$value)
				{
					return $value unless $coercable_item->check($value->{$k});
					$new{$k} = $param->coerce($value->{$k});
				}
				return \%new;
			},
		);
	}
	
	return $C;
};

$lib->get_type("ScalarRef")->{coercion_generator} = sub
{
	my ($parent, $child, $param) = @_;
	return unless $param->has_coercion;
	
	my $coercable_item = $param->coercion->_source_type_union;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	if ($param->coercion->can_be_inlined and $coercable_item->can_be_inlined)
	{
		$C->add_type_coercions($parent => Stringable {
			my @code;
			push @code, 'do { my ($orig, $return_orig, $new) = ($_, 0);';
			push @code,    'for ($$orig) {';
			push @code, sprintf('$return_orig++ && last unless (%s);', $coercable_item->inline_check('$_'));
			push @code, sprintf('$new = (%s);', $param->coercion->inline_coercion('$_'));
			push @code,    '}';
			push @code,    '$return_orig ? $orig : \\$new';
			push @code, '}';
			"@code";
		});
	}
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my $new;
				for my $item ($$value)
				{
					return $value unless $coercable_item->check($item);
					$new = $param->coerce($item);
				}
				return \$new;
			},
		);
	}
	
	return $C;
};

$lib->get_type("Map")->{coercion_generator} = sub
{
	my ($parent, $child, $kparam, $vparam) = @_;
	return unless $kparam->has_coercion || $vparam->has_coercion;
	
	my $kcoercable_item = $kparam->has_coercion ? $kparam->coercion->_source_type_union : $kparam;
	my $vcoercable_item = $vparam->has_coercion ? $vparam->coercion->_source_type_union : $vparam;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	if ((!$kparam->has_coercion or $kparam->coercion->can_be_inlined)
	and (!$vparam->has_coercion or $vparam->coercion->can_be_inlined)
	and $kcoercable_item->can_be_inlined
	and $vcoercable_item->can_be_inlined)
	{
		$C->add_type_coercions($parent => Stringable {
			my @code;
			push @code, 'do { my ($orig, $return_orig, %new) = ($_, 0);';
			push @code,    'for (keys %$orig) {';
			push @code, sprintf('$return_orig++ && last unless (%s);', $kcoercable_item->inline_check('$_'));
			push @code, sprintf('$return_orig++ && last unless (%s);', $vcoercable_item->inline_check('$orig->{$_}'));
			push @code, sprintf('$new{(%s)} = (%s);',
				$kparam->has_coercion ? $kparam->coercion->inline_coercion('$_') : '$_',
				$vparam->has_coercion ? $vparam->coercion->inline_coercion('$orig->{$_}') : '$orig->{$_}',
			);
			push @code,    '}';
			push @code,    '$return_orig ? $orig : \\%new';
			push @code, '}';
			"@code";
		});
	}
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my %new;
				for my $k (keys %$value)
				{
					return $value unless $kcoercable_item->check($k) && $vcoercable_item->check($value->{$k});
					$new{$kparam->has_coercion ? $kparam->coerce($k) : $k} =
						$vparam->has_coercion ? $vparam->coerce($value->{$k}) : $value->{$k};
				}
				return \%new;
			},
		);
	}
	
	return $C;
};

# XXX - also Maybe[`a]?
# XXX - does not seem quite right
$lib->get_type("Optional")->{coercion_generator} = sub
{
	my ($parent, $child, $param) = @_;
	return unless $param->has_coercion;
	return $param->coercion;
};

my $label_counter = 0;
our ($keycheck_counter, @KEYCHECK) = -1;
$lib->get_type("Dict")->{coercion_generator} = sub
{
	my ($parent, $child, %dict) = @_;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	my $all_inlinable = 1;
	for my $tc (values %dict)
	{
		$all_inlinable = 0 if !$tc->can_be_inlined;
		$all_inlinable = 0 if $tc->has_coercion && !$tc->coercion->can_be_inlined;
		last if!$all_inlinable;
	}
	
	if ($all_inlinable)
	{
		$C->add_type_coercions($parent => Stringable {
			require B;
			
			my $keycheck = join "|", map quotemeta, sort { length($b) <=> length($a) or $a cmp $b } keys %dict;
			$keycheck = $KEYCHECK[++$keycheck_counter] = qr{^($keycheck)$}ms; # regexp for legal keys
			
			my $label = sprintf("LABEL%d", ++$label_counter);
			my @code;
			push @code, 'do { my ($orig, $return_orig, %tmp, %new) = ($_, 0);';
			push @code,       "$label: {";
			push @code,       sprintf('($_ =~ $%s::KEYCHECK[%d])||(($return_orig = 1), last %s) for sort keys %%$orig;', __PACKAGE__, $keycheck_counter, $label);
			for my $k (keys %dict)
			{
				my $ct = $dict{$k};
				my $ct_coerce   = $ct->has_coercion;
				my $ct_optional = $ct->is_a_type_of(Types::Standard::Optional());
				my $K = B::perlstring($k);
				
				push @code, "if (exists \$orig->{$K}) {" if $ct_optional;
				if ($ct_coerce)
				{
					push @code, sprintf('%%tmp = (); $tmp{x} = %s;', $ct->coercion->inline_coercion("\$orig->{$K}"));
					push @code, sprintf(
#						$ct_optional
#							? 'if (%s) { $new{%s}=$tmp{x} }'
#							:
						'if (%s) { $new{%s}=$tmp{x} } else { $return_orig = 1; last %s }',
						$ct->inline_check('$tmp{x}'),
						$K,
						$label,
					);
				}
				else
				{
					push @code, sprintf(
#						$ct_optional
#							? 'if (%s) { $new{%s}=$orig->{%s} }'
#							:
						'if (%s) { $new{%s}=$orig->{%s} } else { $return_orig = 1; last %s }',
						$ct->inline_check("\$orig->{$K}"),
						$K,
						$K,
						$label,
					);
				}
				push @code, '}' if $ct_optional;
			}
			push @code,       '}';
			push @code,    '$return_orig ? $orig : \\%new';
			push @code, '}';
			#warn "CODE:: @code";
			"@code";
		});
	}
	
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my %new;
				for my $k (keys %$value)
				{
					return $value unless exists $dict{$k};
				}
				for my $k (keys %dict)
				{
					my $ct = $dict{$k};
					my @accept;
					
					if (exists $value->{$k} and $ct->check($value->{$k}))
					{
						@accept = $value->{$k};
					}
					elsif (exists $value->{$k} and $ct->has_coercion)
					{
						my $x = $ct->coerce($value->{$k});
						@accept = $x if $ct->check($x);
					}
					elsif (exists $value->{$k})
					{
						return $value;
					}
					
					if (@accept)
					{
						$new{$k} = $accept[0];
					}
					elsif (not $ct->is_a_type_of(Types::Standard::Optional()))
					{
						return $value;
					}
				}
				
				return \%new;
			},
		);
	}
	
	return $C;
};

$lib->get_type("Tuple")->{coercion_generator} = sub
{
	my ($parent, $child, @tuple) = @_;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	my $slurpy;
	if (exists $tuple[-1] and ref $tuple[-1] eq "HASH")
	{
		$slurpy = pop(@tuple)->{slurpy};
	}
	
	my $all_inlinable = 1;
	for my $tc (@tuple, ($slurpy ? $slurpy : ()))
	{
		$all_inlinable = 0 if !$tc->can_be_inlined;
		$all_inlinable = 0 if $tc->has_coercion && !$tc->coercion->can_be_inlined;
		last if!$all_inlinable;
	}
	
	if ($all_inlinable)
	{
		$C->add_type_coercions($parent => Stringable {
			my $label = sprintf("LABEL%d", ++$label_counter);
			my @code;
			push @code, 'do { my ($orig, $return_orig, @tmp, @new) = ($_, 0);';
			push @code,       "$label: {";
			push @code,       sprintf('(($return_orig = 1), last %s) if @$orig > %d;', $label, scalar @tuple) unless $slurpy;
			for my $i (0 .. $#tuple)
			{
				my $ct = $tuple[$i];
				my $ct_coerce   = $ct->has_coercion;
				my $ct_optional = $ct->is_a_type_of(Types::Standard::Optional());
				
				if ($ct_coerce)
				{
					push @code, sprintf('@tmp = (); $tmp[0] = %s;', $ct->coercion->inline_coercion("\$orig->[$i]"));
					push @code, sprintf(
						$ct_optional
							? 'if (%s) { $new[%d]=$tmp[0] }'
							: 'if (%s) { $new[%d]=$tmp[0] } else { $return_orig = 1; last %s }',
						$ct->inline_check('$tmp[0]'),
						$i,
						$label,
					);
				}
				else
				{
					push @code, sprintf(
						$ct_optional
							? 'if (%s) { $new[%d]=$orig->[%s] }'
							: 'if (%s) { $new[%d]=$orig->[%s] } else { $return_orig = 1; last %s }',
						$ct->inline_check("\$orig->[$i]"),
						$i,
						$i,
						$label,
					);
				}
			}
			if ($slurpy)
			{
				my $size = @tuple;
				push @code, sprintf('if (@$orig > %d) {', $size);
				push @code, sprintf('my $tail = [ @{$orig}[%d .. $#$orig] ];', $size);
				push @code, $slurpy->has_coercion
					? sprintf('$tail = %s;', $slurpy->coercion->inline_coercion('$tail'))
					: q();
				push @code, sprintf(
					'(%s) ? push(@new, @$tail) : ($return_orig++);',
					$slurpy->inline_check('$tail'),
				);
				push @code, '}';
			}
			push @code,       '}';
			push @code,    '$return_orig ? $orig : \\@new';
			push @code, '}';
			"@code";
		});
	}
	
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				
				if (!$slurpy and @$value > @tuple)
				{
					return $value;
				}
				
				my @new;
				for my $i (0 .. $#tuple)
				{
					my $ct = $tuple[$i];
					my @accept;
					
					if (exists $value->[$i] and $ct->check($value->[$i]))
					{
						@accept = $value->[$i];
					}
					elsif (exists $value->[$i] and $ct->has_coercion)
					{
						my $x = $ct->coerce($value->[$i]);
						@accept = $x if $ct->check($x);
					}
					else
					{
						return $value;
					}
					
					if (@accept)
					{
						$new[$i] = $accept[0];
					}
					elsif (not $ct->is_a_type_of(Types::Standard::Optional()))
					{
						return $value;
					}
				}
				
				if ($slurpy and @$value > @tuple)
				{
					my $tmp = $slurpy->has_coercion
						? $slurpy->coerce([ @{$value}[@tuple .. $#$value] ])
						: [ @{$value}[@tuple .. $#$value] ];
					$slurpy->check($tmp) ? push(@new, @$tmp) : return($value);
				}
				
				return \@new;
			},
		);
	};
	
	return $C;
};

1;

__END__

=pod

=for stopwords booleans vstrings typeglobs

=encoding utf-8

=for stopwords datetimes

=head1 NAME

Types::Standard - bundled set of built-in types for Type::Tiny

=head1 DESCRIPTION

L<Type::Tiny> bundles a few types which seem to be useful.

=head2 Moose-like

The following types are similar to those described in
L<Moose::Util::TypeConstraints>.

=over

=item C<< Any >>

Absolutely any value passes this type constraint (even undef).

=item C<< Item >>

Essentially the same as C<Any>. All other type constraints in this library
inherit directly or indirectly from C<Item>.

=item C<< Bool >>

Values that are reasonable booleans. Accepts 1, 0, the empty string and
undef.

=item C<< Maybe[`a] >>

Given another type constraint, also accepts undef. For example,
C<< Maybe[Int] >> accepts all integers plus undef.

=item C<< Undef >>

Only undef passes this type constraint.

=item C<< Defined >>

Only undef fails this type constraint.

=item C<< Value >>

Any defined, non-reference value.

=item C<< Str >>

Any string.

(The only difference between C<Value> and C<Str> is that the former accepts
typeglobs and vstrings.)

=item C<< Num >>

See C<LaxNum> and C<StrictNum> below.

=item C<< Int >>

An integer; that is a string of digits 0 to 9, optionally prefixed with a
hyphen-minus character.

=item C<< ClassName >>

The name of a loaded package. The package must have C<< @ISA >> or
C<< $VERSION >> defined, or must define at least one sub to be considered
a loaded package.

=item C<< RoleName >>

Like C<< ClassName >>, but the package must I<not> define a method called
C<new>. This is subtly different from Moose's type constraint of the same
name; let me know if this causes you any problems. (I can't promise I'll
change anything though.)

=item C<< Ref[`a] >>

Any defined reference value, including blessed objects.

Unlike Moose, C<Ref> is a parameterized type, allowing Scalar::Util::reftype
checks, a la

   Ref["HASH"]  # hashrefs, including blessed hashrefs

=item C<< ScalarRef[`a] >>

A value where C<< ref($value) eq "SCALAR" or ref($value) eq "REF" >>.

If parameterized, the referred value must pass the additional constraint.
For example, C<< ScalarRef[Int] >> must be a reference to a scalar which
holds an integer value.

=item C<< ArrayRef[`a] >>

A value where C<< ref($value) eq "ARRAY" >>.

If parameterized, the elements of the array must pass the additional
constraint. For example, C<< ArrayRef[Num] >> must be a reference to an
array of numbers.

=item C<< HashRef[`a] >>

A value where C<< ref($value) eq "HASH" >>.

If parameterized, the values of the hash must pass the additional
constraint. For example, C<< HashRef[Num] >> must be a reference to an
hash where the values are numbers. The hash keys are not constrained,
but Perl limits them to strings; see C<Map> below if you need to further
constrain the hash values.

=item C<< CodeRef >>

A value where C<< ref($value) eq "CODE" >>.

=item C<< RegexpRef >>

A value where C<< ref($value) eq "Regexp" >>.

=item C<< GlobRef >>

A value where C<< ref($value) eq "GLOB" >>.

=item C<< FileHandle >>

A file handle.

=item C<< Object >>

A blessed object.

(This also accepts regexp refs.)

=back

=head2 Structured

OK, so I stole some ideas from L<MooseX::Types::Structured>.

=over

=item C<< Map[`k, `v] >>

Similar to C<HashRef> but parameterized with type constraints for both the
key and value. The constraint for keys would typically be a subtype of
C<Str>.

=item C<< Tuple[...] >>

Subtype of C<ArrayRef>, accepting an list of type constraints for
each slot in the array.

C<< Tuple[Int, HashRef] >> would match C<< [1, {}] >> but not C<< [{}, 1] >>.

=item C<< Dict[...] >>

Subtype of C<HashRef>, accepting an list of type constraints for
each slot in the hash.

For example C<< Dict[name => Str, id => Int] >> allows
C<< { name => "Bob", id => 42 } >>.

=item C<< Optional[`a] >>

Used in conjunction with C<Dict> and C<Tuple> to specify slots that are
optional and may be omitted (but not necessarily set to an explicit undef).

C<< Dict[name => Str, id => Optional[Int]] >> allows C<< { name => "Bob" } >>
but not C<< { name => "Bob", id => "BOB" } >>.

=back

This module also exports a C<slurpy> function, which can be used as follows:

   my $type = Tuple[Str, slurpy ArrayRef[Int]];
   
   $type->( ["Hello"] );                # ok
   $type->( ["Hello", 1, 2, 3] );       # ok
   $type->( ["Hello", [1, 2, 3]] );     # not ok

=begin trustme

=item slurpy

=end trustme

=head2 Objects

OK, so I stole some ideas from L<MooX::Types::MooseLike::Base>.

=over

=item C<< InstanceOf[`a] >>

Shortcut for a union of L<Type::Tiny::Class> constraints.

C<< InstanceOf["Foo", "Bar"] >> allows objects blessed into the C<Foo>
or C<Bar> classes, or subclasses of those.

Given no parameters, just equivalent to C<Object>.

=item C<< ConsumerOf[`a] >>

Shortcut for an intersection of L<Type::Tiny::Role> constraints.

C<< ConsumerOf["Foo", "Bar"] >> allows objects where C<< $o->DOES("Foo") >>
and C<< $o->DOES("Bar") >> both return true.

Given no parameters, just equivalent to C<Object>.

=item C<< HasMethods[`a] >>

Shortcut for a L<Type::Tiny::Duck> constraint.

C<< HasMethods["foo", "bar"] >> allows objects where C<< $o->can("foo") >>
and C<< $o->can("bar") >> both return true.

Given no parameters, just equivalent to C<Object>.

=back

=head2 More

There are a few other types exported by this function:

=over

=item C<< Overload[`a] >>

With no parameters, checks that the value is an overloaded object. Can
be given one or more string parameters, which are specific operations
to check are overloaded. For example, the following checks for objects
which overload addition and subtraction.

   Overload["+", "-"]

=item C<< Tied[`a] >>

A reference to a tied scalar, array or hash.

Can be parameterized with a type constraint which will be applied to
the object returned by the C<< tied() >> function. As a convenience,
can also be parameterized with a string, which will be inflated to a
L<Type::Tiny::Class>.

   use Types::Standard qw(Tied);
   use Type::Utils qw(class_type);
   
   my $My_Package = class_type { class => "My::Package" };
   
   tie my %h, "My::Package";
   \%h ~~ Tied;                   # true
   \%h ~~ Tied[ $My_Package ];    # true
   \%h ~~ Tied["My::Package"];    # true
   
   tie my $s, "Other::Package";
   \$s ~~ Tied;                   # true
   $s  ~~ Tied;                   # false !!

If you need to check that something is specifically a reference to
a tied hash, use an intersection:

   use Types::Standard qw( Tied HashRef );
   
   my $TiedHash = (Tied) & (HashRef);
   
   tie my %h, "My::Package";
   tie my $s, "Other::Package";
   
   \%h ~~ $TiedHash;     # true
   \$s ~~ $TiedHash;     # false

=item C<< StrMatch[`a] >>

A string that matches a regular expression:

   declare "Distance",
      as StrMatch[ qr{^([0-9]+)\s*(mm|cm|m|km)$} ];

You can optionally provide a type constraint for the array of subexpressions:

   declare "Distance",
      as StrMatch[
         qr{^([0-9]+)\s*(.+)$},
         Tuple[
            Int,
            enum(DistanceUnit => [qw/ mm cm m km /]),
         ],
      ];

=item C<< Enum[`a] >>

As per MooX::Types::MooseLike::Base:

   has size => (is => "ro", isa => Enum[qw( S M L XL XXL )]);

=item C<< OptList >>

An arrayref of arrayrefs in the style of L<Data::OptList> output.

=item C<< LaxNum >>, C<< StrictNum >>

In Moose 2.09, the C<Num> type constraint implementation was changed from
being a wrapper around L<Scalar::Util>'s C<looks_like_number> function to
a stricter regexp (which disallows things like "-Inf" and "Nan").

Types::Standard provides I<both> implementations. C<LaxNum> is measurably
faster.

The C<Num> type constraint is currently an alias for C<LaxNum> unless you
set the C<PERL_TYPES_STANDARD_STRICTNUM> environment variable to true before
loading Types::Standard, in which case it becomes an alias for C<StrictNum>.
The constant C<< Types::Standard::STRICTNUM >> can be used to check if
C<Num> is being strict.

Most people should probably use C<Num> or C<StrictNum>. Don't explicitly
use C<LaxNum> unless you specifically need an attribute which will accept
things like "Inf".

=back

=head2 Coercions

None of the types in this type library have any coercions by default.
However some standalone coercions may be exported. These can be combined
with type constraints using the C<< + >> operator.

=over

=item C<< MkOpt >>

A coercion from C<ArrayRef>, C<HashRef> or C<Undef> to C<OptList>. Example
usage in a Moose attribute:

   use Types::Standard qw( OptList MkOpt );
   
   has options => (
      is     => "ro",
      isa    => OptList + MkOpt,
      coerce => 1,
   );

=item C<< Split[`a] >>

Split a string on a regexp.

   use Types::Standard qw( ArrayRef Str Split );
   
   has name => (
      is     => "ro",
      isa    => (ArrayRef[Str]) + (Split[qr/\s/]),
      coerce => 1,
   );

=item C<< Join[`a] >>

Join an array of strings with a delimiter.

   use Types::Standard qw( Str Join );
   
   my $FileLines = Str + Join["\n"];
   
   has file_contents => (
      is     => "ro",
      isa    => $FileLines,
      coerce => 1,
   );

=back

=head2 Constants

=over

=item C<< Types::Standard::STRICTNUM >>

Indicates whether C<Num> is an alias for C<StrictNum>. (It is usually an
alias for C<LaxNum>.)

=back

=begin private

=item Stringable

=end private

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny::Manual>.

L<Type::Tiny>, L<Type::Library>, L<Type::Utils>, L<Type::Coercion>.

L<Moose::Util::TypeConstraints>,
L<Mouse::Util::TypeConstraints>,
L<MooseX::Types::Structured>.

L<Types::XSD> provides some type constraints based on XML Schema's data
types; this includes constraints for ISO8601-formatted datetimes, integer
ranges (e.g. C<< PositiveInteger[maxInclusive=>10] >> and so on.

L<Types::Encodings> provides C<Bytes> and C<Chars> type constraints that
were formerly found in Types::Standard.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

