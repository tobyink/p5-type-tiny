package Types::Standard;

use strict;
use warnings;

BEGIN {
	$Types::Standard::AUTHORITY = 'cpan:TOBYINK';
	$Types::Standard::VERSION   = '0.005_05';
}

use base "Type::Library";

our @EXPORT_OK = qw( slurpy );

use Scalar::Util qw( blessed looks_like_number );
use Type::Utils;
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

declare "Any",
	_is_core => 1,
	inline_as { "!!1" };

declare "Item",
	_is_core => 1,
	inline_as { "!!1" };

declare "Bool",
	_is_core => 1,
	as "Item",
	where { !defined $_ or $_ eq q() or $_ eq '0' or $_ eq '1' },
	inline_as { "!defined $_ or $_ eq q() or $_ eq '0' or $_ eq '1'" };

declare "Undef",
	_is_core => 1,
	as "Item",
	where { !defined $_ },
	inline_as { "!defined($_)" };

declare "Defined",
	_is_core => 1,
	as "Item",
	where { defined $_ },
	inline_as { "defined($_)" };

declare "Value",
	_is_core => 1,
	as "Defined",
	where { not ref $_ },
	inline_as { "defined($_) and not ref($_)" };

declare "Str",
	_is_core => 1,
	as "Value",
	where { ref(\$_) eq 'SCALAR' or ref(\(my $val = $_)) eq 'SCALAR' },
	inline_as {
		"defined($_) and do { ref(\\$_) eq 'SCALAR' or ref(\\(my \$val = $_)) eq 'SCALAR' }"
	};

declare "Num",
	_is_core => 1,
	as "Str",
	where { looks_like_number $_ },
	inline_as { "!ref($_) && Scalar::Util::looks_like_number($_)" };

declare "Int",
	_is_core => 1,
	as "Num",
	where { /\A-?[0-9]+\z/ },
	inline_as { "defined $_ and $_ =~ /\\A-?[0-9]+\\z/" };

declare "ClassName",
	_is_core => 1,
	as "Str",
	where { goto \&_is_class_loaded },
	inline_as { "Types::Standard::_is_class_loaded($_)" };

declare "RoleName",
	as "ClassName",
	where { not $_->can("new") },
	inline_as { "Types::Standard::_is_class_loaded($_) and not $_->can('new')" };

declare "Ref",
	_is_core => 1,
	as "Defined",
	where { ref $_ },
	inline_as { "!!ref($_)" },
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
	};
	
declare "CodeRef",
	_is_core => 1,
	as "Ref",
	where { ref $_ eq "CODE" },
	inline_as { "ref($_) eq 'CODE'" };

declare "RegexpRef",
	_is_core => 1,
	as "Ref",
	where { ref $_ eq "Regexp" },
	inline_as { "ref($_) eq 'Regexp'" };

declare "GlobRef",
	_is_core => 1,
	as "Ref",
	where { ref $_ eq "GLOB" },
	inline_as { "ref($_) eq 'GLOB'" };

declare "FileHandle",
	_is_core => 1,
	as "Ref",
	where {
		(ref($_) eq "GLOB" && Scalar::Util::openhandle($_))
		or (blessed($_) && $_->isa("IO::Handle"))
	},
	inline_as {
		"(ref($_) eq \"GLOB\" && Scalar::Util::openhandle($_)) ".
		"or (Scalar::Util::blessed($_) && $_->isa(\"IO::Handle\"))"
	};

declare "ArrayRef",
	_is_core => 1,
	as "Ref",
	where { ref $_ eq "ARRAY" },
	inline_as { "ref($_) eq 'ARRAY'" },
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
	};

declare "HashRef",
	_is_core => 1,
	as "Ref",
	where { ref $_ eq "HASH" },
	inline_as { "ref($_) eq 'HASH'" },
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
	};

declare "ScalarRef",
	_is_core => 1,
	as "Ref",
	where { ref $_ eq "SCALAR" or ref $_ eq "REF" },
	inline_as { "ref($_) eq 'SCALAR' or ref($_) eq 'REF'" },
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
	};

declare "Object",
	_is_core => 1,
	as "Ref",
	where { blessed $_ },
	inline_as { "Scalar::Util::blessed($_)" };

declare "Maybe",
	_is_core => 1,
	as "Item",
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
	};

declare "Map",
	as "HashRef",
	where { ref $_ eq "HASH" },
	inline_as { "ref($_) eq 'HASH'" },
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
	};

declare "Optional",
	as "Item",
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
	};

sub slurpy {
	my $t = shift;
	wantarray ? (+{ slurpy => $t }, @_) : +{ slurpy => $t };
}

declare "Tuple",
	as "ArrayRef",
	where { ref $_ eq "ARRAY" },
	inline_as { "ref($_) eq 'ARRAY'" },
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
	};

declare "Dict",
	as "HashRef",
	where { ref $_ eq "HASH" },
	inline_as { "ref($_) eq 'HASH'" },
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
	};

use overload ();
declare "Overload",
	as "Object",
	where { overload::Overloaded($_) },
	inline_as { "Scalar::Util::blessed($_) and overload::Overloaded($_)" },
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
	};

declare "StrMatch",
	as "Str",
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
		$regexp_string =~ s/\\\//\\\\\//g; # toothpicks
		if ($checker)
		{
			return unless $checker->can_be_inlined;
			return sub
			{
				my $v = $_[1];
				sprintf
					"!ref($v) and do { my \$m = [$v =~ /%s/]; %s }",
					$regexp_string,
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
					"!ref($v) and $v =~ /%s/",
					$regexp_string,
				;
			};
		}
	};

declare "OptList",
	as ArrayRef([ArrayRef()]),
	where {
		for my $inner (@$_) {
			return unless @$inner == 2;
			return unless is_Str($inner->[0]);
		}
		return !!1;
	},
	inline_as {
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
	};

declare "Tied",
	as "Ref",
	where {
		!!tied(Scalar::Util::reftype($_) eq 'HASH' ?  %{$_} : Scalar::Util::reftype($_) eq 'ARRAY' ?  @{$_} :  ${$_})
	}
	inline_as {
		my $self = shift;
		$self->parent->inline_check(@_)
		. " and !!tied(Scalar::Util::reftype($_) eq 'HASH' ? \%{$_} : Scalar::Util::reftype($_) eq 'ARRAY' ? \@{$_} : \${$_})"
	}
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
	};

declare_coercion "MkOpt",
	to_type "OptList",
	from    "ArrayRef", q{ Exporter::TypeTiny::mkopt($_) },
	from    "HashRef",  q{ Exporter::TypeTiny::mkopt($_) },
	from    "Undef",    q{ [] };

declare_coercion "Join", to_type "Str" => {
	coercion_generator => sub {
		my ($self, $target, $sep) = @_;
		Types::TypeTiny::StringLike->check($sep)
			or _croak("Parameter to Join[`a] expected to be a string; got $sep");
		require B;
		$sep = B::perlstring($sep);
		return (ArrayRef(), qq{ join($sep, \@\$_) });
	},
};

declare_coercion "Split", to_type ArrayRef() => {
	coercion_generator => sub {
		my ($self, $target, $re) = @_;
		ref($re) eq q(Regexp)
			or _croak("Parameter to Split[`a] expected to be a regular expresssion; got $re");
		my $regexp_string = "$re";
		$regexp_string =~ s/\\\//\\\\\//g; # toothpicks
		return (Str(), qq{ [split /$regexp_string/, \$_] });
	},
};

require Types::Standard::DeepCoercion;

1;

__END__

=pod

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

=item C<< Item >>

=item C<< Bool >>

=item C<< Maybe[`a] >>

=item C<< Undef >>

=item C<< Defined >>

=item C<< Value >>

=item C<< Str >>

=item C<< Num >>

=item C<< Int >>

=item C<< ClassName >>

=item C<< RoleName >>

=item C<< Ref[`a] >>

=item C<< ScalarRef[`a] >>

=item C<< ArrayRef[`a] >>

=item C<< HashRef[`a] >>

=item C<< CodeRef >>

=item C<< RegexpRef >>

=item C<< GlobRef >>

=item C<< FileHandle >>

=item C<< Object >>

=back

Unlike Moose, C<Ref> is a parameterized type, allowing Scalar::Util::reftype
checks, a la

   Ref["HASH"]  # hashrefs, including blessed hashrefs

=head2 Structured

OK, so I stole some ideas from L<MooseX::Types::Structured>.

=over

=item C<< Map[`a] >>

=item C<< Tuple[`a] >>

=item C<< Dict[`a] >>

=item C<< Optional[`a] >>

=back

This module also exports a C<slurpy> function.

=begin trustme

=item slurpy

=end trustme

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

A string that matches a regular exception:

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

=item C<< OptList >>

An arrayref of arrayrefs in the style of L<Data::OptList> output.

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

