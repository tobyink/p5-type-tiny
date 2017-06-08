package Types::Standard;

use 5.006001;
use strict;
use warnings;

BEGIN {
	eval { require re };
	if ($] < 5.008) { require Devel::TypeTiny::Perl56Compat };
	if ($] < 5.010) { require Devel::TypeTiny::Perl58Compat };
}

BEGIN {
	$Types::Standard::AUTHORITY = 'cpan:TOBYINK';
	$Types::Standard::VERSION   = '1.002001';
}

use Type::Library -base;

our @EXPORT_OK = qw( slurpy );

use Scalar::Util qw( blessed looks_like_number );
use Type::Tiny ();
use Types::TypeTiny ();

BEGIN {
	*_is_class_loaded = Type::Tiny::_USE_XS
		? \&Type::Tiny::XS::Util::is_class_loaded
		: sub {
			return !!0 if ref $_[0];
			return !!0 if not $_[0];
			my $stash = do { no strict 'refs'; \%{"$_[0]\::"} };
			return !!1 if exists $stash->{'ISA'};
			return !!1 if exists $stash->{'VERSION'};
			foreach my $globref (values %$stash) {
				return !!1 if *{$globref}{CODE};
			}
			return !!0;
		};
};

my $HAS_RUXS = eval {
	require Ref::Util::XS;
	Ref::Util::XS::->VERSION(0.100);
	1;
};

my $add_core_type = sub {
	my $meta = shift;
	my ($typedef) = @_;
	
	my $name = $typedef->{name};
	my ($xsub, $xsubname);
	
	# We want Map and Tuple to be XSified, even if they're not
	# really core.
	$typedef->{_is_core} = 1
		unless $name eq 'Map' || $name eq 'Tuple';

	if ( Type::Tiny::_USE_XS
	and not ($name eq 'RegexpRef') ) {
		$xsub     = Type::Tiny::XS::get_coderef_for($name);
		$xsubname = Type::Tiny::XS::get_subname_for($name);
	}
		
	elsif ( Type::Tiny::_USE_MOUSE
	and not ($name eq 'RegexpRef' or $name eq 'Int' or $name eq 'Object') ) {
		require Mouse::Util::TypeConstraints;
		$xsub     = "Mouse::Util::TypeConstraints"->can($name);
		$xsubname = "Mouse::Util::TypeConstraints::$name" if $xsub;
	}
	
	$typedef->{compiled_type_constraint} = $xsub if $xsub;
	
	$typedef->{inlined} = sub { "$xsubname\($_[1])" }
		if defined($xsubname) and (
			# These should be faster than their normal inlined
			# equivalents
			$name eq 'Str' or
			$name eq 'Bool' or
			$name eq 'ClassName' or
			$name eq 'RegexpRef' or
			$name eq 'FileHandle'
		);
	
	$meta->add_type($typedef);
};

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

my $meta = __PACKAGE__->meta;

# Stringable and LazyLoad are optimizations that complicate
# this module somewhat, but they have led to performance
# improvements. If Types::Standard wasn't such a key type
# library, I wouldn't use them. I strongly discourage anybody
# from using them in their own code. If you're looking for
# examples of how to write a type library sanely, you're
# better off looking at the code for Types::Common::Numeric
# and Types::Common::String.

sub Stringable (&)
{
	package #private
	Types::Standard::_Stringable;
	use overload q[""] => sub { $_[0]{text} ||= $_[0]{code}->() }, fallback => 1;
	bless +{ code => $_[0] };
}

sub LazyLoad ($$)
{
	package #private
	Types::Standard::LazyLoad;
	use overload fallback => 1, q[&{}] => sub {
		my ($typename, $function) = @{$_[0]};
		my $type  = $meta->get_type($typename);
		my $class = "Types::Standard::$typename";
		eval "require $class; 1" or die($@);
		# Majorly break encapsulation for Type::Tiny :-O
		for my $key (keys %$type)
		{
			next unless ref($type->{$key}) eq __PACKAGE__;
			my $f = $type->{$key}[1];
			$type->{$key} = $class->can("__$f");
		}
		return $class->can("__$function");
	};
	bless \@_;
}

no warnings;

BEGIN { *STRICTNUM = $ENV{PERL_TYPES_STANDARD_STRICTNUM} ? sub(){!!1} : sub(){!!0} };

my $_any = $meta->$add_core_type({
	name       => "Any",
	inlined    => sub { "!!1" },
});

my $_item = $meta->$add_core_type({
	name       => "Item",
	inlined    => sub { "!!1" },
	parent     => $_any,
});

$meta->$add_core_type({
	name       => "Bool",
	parent     => $_item,
	constraint => sub { !defined $_ or $_ eq q() or $_ eq '0' or $_ eq '1' },
	inlined    => sub { "!defined $_[1] or $_[1] eq q() or $_[1] eq '0' or $_[1] eq '1'" },
});

my $_undef = $meta->$add_core_type({
	name       => "Undef",
	parent     => $_item,
	constraint => sub { !defined $_ },
	inlined    => sub { "!defined($_[1])" },
});

my $_def = $meta->$add_core_type({
	name       => "Defined",
	parent     => $_item,
	constraint => sub { defined $_ },
	inlined    => sub { "defined($_[1])" },
});

my $_val = $meta->$add_core_type({
	name       => "Value",
	parent     => $_def,
	constraint => sub { not ref $_ },
	inlined    => sub { "defined($_[1]) and not ref($_[1])" },
});

my $_str = $meta->$add_core_type({
	name       => "Str",
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
	inlined    => sub { "defined($_[1]) && !ref($_[1]) && Scalar::Util::looks_like_number($_[1])" },
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
	parent     => (STRICTNUM ? $_strictnum : $_laxnum),
});

$meta->$add_core_type({
	name       => "Int",
	parent     => $_num,
	constraint => sub { /\A-?[0-9]+\z/ },
	inlined    => sub { "defined($_[1]) and !ref($_[1]) and $_[1] =~ /\\A-?[0-9]+\\z/" },
});

my $_classn = $meta->add_type({
	name       => "ClassName",
	parent     => $_str,
	constraint => \&_is_class_loaded,
	inlined    => sub { "Types::Standard::_is_class_loaded(do { my \$tmp = $_[1] })" },
});

$meta->add_type({
	name       => "RoleName",
	parent     => $_classn,
	constraint => sub { not $_->can("new") },
	inlined    => sub { "Types::Standard::_is_class_loaded(do { my \$tmp = $_[1] }) and not $_[1]\->can('new')" },
});

my $_ref = $meta->$add_core_type({
	name       => "Ref",
	parent     => $_def,
	constraint => sub { ref $_ },
	inlined    => sub { "!!ref($_[1])" },
	constraint_generator => sub
	{
		return $meta->get_type('Ref') unless @_;
		
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

$meta->$add_core_type({
	name       => "CodeRef",
	parent     => $_ref,
	constraint => sub { ref $_ eq "CODE" },
	inlined    => $HAS_RUXS
		? sub { "Ref::Util::XS::is_plain_coderef($_[1])" }
		: sub { "ref($_[1]) eq 'CODE'" },
});

my $_regexp = $meta->$add_core_type({
	name       => "RegexpRef",
	parent     => $_ref,
	constraint => sub { ref($_) && !!re::is_regexp($_) or blessed($_) && $_->isa('Regexp') },
	inlined    => sub { my $v = $_[1]; "ref($v) && !!re::is_regexp($v) or Scalar::Util::blessed($v) && $v\->isa('Regexp')" },
});

$meta->$add_core_type({
	name       => "GlobRef",
	parent     => $_ref,
	constraint => sub { ref $_ eq "GLOB" },
	inlined    => $HAS_RUXS
		? sub { "Ref::Util::XS::is_plain_globref($_[1])" }
		: sub { "ref($_[1]) eq 'GLOB'" },
});

$meta->$add_core_type({
	name       => "FileHandle",
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

my $_arr = $meta->$add_core_type({
	name       => "ArrayRef",
	parent     => $_ref,
	constraint => sub { ref $_ eq "ARRAY" },
	inlined    => $HAS_RUXS
		? sub { "Ref::Util::XS::is_plain_arrayref($_[1])" }
		: sub { "ref($_[1]) eq 'ARRAY'" },
	constraint_generator => LazyLoad(ArrayRef => 'constraint_generator'),
	inline_generator     => LazyLoad(ArrayRef => 'inline_generator'),
	deep_explanation     => LazyLoad(ArrayRef => 'deep_explanation'),
	coercion_generator   => LazyLoad(ArrayRef => 'coercion_generator'),
});

my $_hash = $meta->$add_core_type({
	name       => "HashRef",
	parent     => $_ref,
	constraint => sub { ref $_ eq "HASH" },
	inlined    => $HAS_RUXS
		? sub { "Ref::Util::XS::is_plain_hashref($_[1])" }
		: sub { "ref($_[1]) eq 'HASH'" },
	constraint_generator => LazyLoad(HashRef => 'constraint_generator'),
	inline_generator     => LazyLoad(HashRef => 'inline_generator'),
	deep_explanation     => LazyLoad(HashRef => 'deep_explanation'),
	coercion_generator   => LazyLoad(HashRef => 'coercion_generator'),
	my_methods => {
		hashref_allows_key => sub {
			my $self = shift;
			Str()->check($_[0]);
		},
		hashref_allows_value => sub {
			my $self = shift;
			my ($key, $value) = @_;
			
			return !!0 unless $self->my_hashref_allows_key($key);
			return !!1 if $self==HashRef();
			
			my $href  = $self->find_parent(sub { $_->has_parent && $_->parent==HashRef() });
			my $param = $href->type_parameter;
			
			Str()->check($key) and $param->check($value);
		},
	},
});

$meta->$add_core_type({
	name       => "ScalarRef",
	parent     => $_ref,
	constraint => sub { ref $_ eq "SCALAR" or ref $_ eq "REF" },
	inlined    => sub { "ref($_[1]) eq 'SCALAR' or ref($_[1]) eq 'REF'" },
	constraint_generator => LazyLoad(ScalarRef => 'constraint_generator'),
	inline_generator     => LazyLoad(ScalarRef => 'inline_generator'),
	deep_explanation     => LazyLoad(ScalarRef => 'deep_explanation'),
	coercion_generator   => LazyLoad(ScalarRef => 'coercion_generator'),
});

my $_obj = $meta->$add_core_type({
	name       => "Object",
	parent     => $_ref,
	constraint => sub { blessed $_ },
	inlined    => $HAS_RUXS
		? sub { "Ref::Util::XS::is_blessed_ref($_[1])" }
		: sub { "Scalar::Util::blessed($_[1])" },
});

$meta->$add_core_type({
	name       => "Maybe",
	parent     => $_item,
	constraint_generator => sub
	{
		return $meta->get_type('Maybe') unless @_;
		
		my $param = Types::TypeTiny::to_TypeTiny(shift);
		Types::TypeTiny::TypeTiny->check($param)
			or _croak("Parameter to Maybe[`a] expected to be a type constraint; got $param");
		
		my $param_compiled_check = $param->compiled_check;
		my @xsub;
		if (Type::Tiny::_USE_XS)
		{
			my $paramname = Type::Tiny::XS::is_known($param_compiled_check);
			push @xsub, Type::Tiny::XS::get_coderef_for("Maybe[$paramname]")
				if $paramname;
		}
		elsif (Type::Tiny::_USE_MOUSE and $param->_has_xsub)
		{
			require Mouse::Util::TypeConstraints;
			my $maker = "Mouse::Util::TypeConstraints"->can("_parameterize_Maybe_for");
			push @xsub, $maker->($param) if $maker;
		}
		
		return(
			sub
			{
				my $value = shift;
				return !!1 unless defined $value;
				return $param->check($value);
			},
			@xsub,
		);
	},
	inline_generator => sub {
		my $param = shift;
		
		my $param_compiled_check = $param->compiled_check;
		if (Type::Tiny::_USE_XS)
		{
			my $paramname = Type::Tiny::XS::is_known($param_compiled_check);
			my $xsubname  = Type::Tiny::XS::get_subname_for("Maybe[$paramname]");
			return sub { "$xsubname\($_[1]\)" } if $xsubname;
		}
		
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
			@{ $param->validate_explain($value, $varname) },
		];
	},
	coercion_generator => sub
	{
		my ($parent, $child, $param) = @_;
		return unless $param->has_coercion;
		return $param->coercion;
	},
});

my $_map = $meta->$add_core_type({
	name       => "Map",
	parent     => $_hash,
	constraint_generator => LazyLoad(Map => 'constraint_generator'),
	inline_generator     => LazyLoad(Map => 'inline_generator'),
	deep_explanation     => LazyLoad(Map => 'deep_explanation'),
	coercion_generator   => LazyLoad(Map => 'coercion_generator'),
	my_methods => {
		hashref_allows_key => sub {
			my $self = shift;
			my ($key) = @_;
			
			return Str()->check($key) if $self==Map();
			
			my $map = $self->find_parent(sub { $_->has_parent && $_->parent==Map() });
			my ($kcheck, $vcheck) = @{ $map->parameters };
			
			($kcheck or Any())->check($key);
		},
		hashref_allows_value => sub {
			my $self = shift;
			my ($key, $value) = @_;
			
			return !!0 unless $self->my_hashref_allows_key($key);
			return !!1 if $self==Map();
			
			my $map = $self->find_parent(sub { $_->has_parent && $_->parent==Map() });
			my ($kcheck, $vcheck) = @{ $map->parameters };
			
			($kcheck or Any())->check($key)
				and ($vcheck or Any())->check($value);
		},
	},
});

my $_Optional = $meta->add_type({
	name       => "Optional",
	parent     => $_item,
	constraint_generator => sub
	{
		return $meta->get_type('Optional') unless @_;
		
		my $param = Types::TypeTiny::to_TypeTiny(shift);
		Types::TypeTiny::TypeTiny->check($param)
			or _croak("Parameter to Optional[`a] expected to be a type constraint; got $param");
		
		sub { $param->check($_[0]) }
	},
	inline_generator => sub {
		my $param = shift;
		return unless $param->can_be_inlined;
		return sub {
			my $v = $_[1];
			$param->inline_check($v);
		};
	},
	deep_explanation => sub {
		my ($type, $value, $varname) = @_;
		my $param = $type->parameters->[0];
		
		return [
			sprintf('%s exists', $varname),
			sprintf('"%s" constrains %s with "%s" if it exists', $type, $varname, $param),
			@{ $param->validate_explain($value, $varname) },
		];
	},
	coercion_generator => sub
	{
		my ($parent, $child, $param) = @_;
		return unless $param->has_coercion;
		return $param->coercion;
	},
});

sub slurpy {
	my $t = shift;
	wantarray ? (+{ slurpy => $t }, @_) : +{ slurpy => $t };
}

$meta->$add_core_type({
	name       => "Tuple",
	parent     => $_arr,
	name_generator => sub
	{
		my ($s, @a) = @_;
		sprintf('%s[%s]', $s, join q[,], map { ref($_) eq "HASH" ? sprintf("slurpy %s", $_->{slurpy}) : $_ } @a);
	},
	constraint_generator => LazyLoad(Tuple => 'constraint_generator'),
	inline_generator     => LazyLoad(Tuple => 'inline_generator'),
	deep_explanation     => LazyLoad(Tuple => 'deep_explanation'),
	coercion_generator   => LazyLoad(Tuple => 'coercion_generator'),
});

$meta->add_type({
	name       => "CycleTuple",
	parent     => $_arr,
	name_generator => sub
	{
		my ($s, @a) = @_;
		sprintf('%s[%s]', $s, join q[,], @a);
	},
	constraint_generator => LazyLoad(CycleTuple => 'constraint_generator'),
	inline_generator     => LazyLoad(CycleTuple => 'inline_generator'),
	deep_explanation     => LazyLoad(CycleTuple => 'deep_explanation'),
	coercion_generator   => LazyLoad(CycleTuple => 'coercion_generator'),
});

$meta->add_type({
	name       => "Dict",
	parent     => $_hash,
	name_generator => sub
	{
		my ($s, @p) = @_;
		my $l = ref($p[-1]) eq q(HASH) ? pop(@p)->{slurpy} : undef;
		my %a = @p;
		sprintf('%s[%s%s]', $s, join(q[,], map sprintf("%s=>%s", $_, $a{$_}), sort keys %a), $l ? ",slurpy $l" : '');
	},
	constraint_generator => LazyLoad(Dict => 'constraint_generator'),
	inline_generator     => LazyLoad(Dict => 'inline_generator'),
	deep_explanation     => LazyLoad(Dict => 'deep_explanation'),
	coercion_generator   => LazyLoad(Dict => 'coercion_generator'),
	my_methods => {
		dict_is_slurpy => sub
		{
			my $self = shift;
			
			return !!0 if $self==Dict();
			
			my $dict = $self->find_parent(sub { $_->has_parent && $_->parent==Dict() });
			ref($dict->parameters->[-1]) eq q(HASH)
				? $dict->parameters->[-1]{slurpy}
				: !!0
		},
		hashref_allows_key => sub
		{
			my $self = shift;
			my ($key) = @_;
			
			return Str()->check($key) if $self==Dict();
			
			my $dict = $self->find_parent(sub { $_->has_parent && $_->parent==Dict() });
			my %params;
			my $slurpy = $dict->my_dict_is_slurpy;
			if ($slurpy)
			{
				my @args = @{$dict->parameters};
				pop @args;
				%params = @args;
			}
			else
			{
				%params = @{ $dict->parameters }
			}
			
			return !!1
				if exists($params{$key});
			return !!0
				if !$slurpy;
			return Str()->check($key)
				if $slurpy==Any() || $slurpy==Item() || $slurpy==Defined() || $slurpy==Ref();
			return $slurpy->my_hashref_allows_key($key)
				if $slurpy->is_a_type_of(HashRef());
			return !!0;
		},
		hashref_allows_value => sub
		{
			my $self = shift;
			my ($key, $value) = @_;
			
			return !!0 unless $self->my_hashref_allows_key($key);
			return !!1 if $self==Dict();
			
			my $dict = $self->find_parent(sub { $_->has_parent && $_->parent==Dict() });
			my %params;
			my $slurpy = $dict->my_dict_is_slurpy;
			if ($slurpy)
			{
				my @args = @{$dict->parameters};
				pop @args;
				%params = @args;
			}
			else
			{
				%params = @{ $dict->parameters }
			}
			
			return !!1
				if exists($params{$key}) && $params{$key}->check($value);
			return !!0
				if !$slurpy;
			return !!1
				if $slurpy==Any() || $slurpy==Item() || $slurpy==Defined() || $slurpy==Ref();
			return $slurpy->my_hashref_allows_value($key, $value)
				if $slurpy->is_a_type_of(HashRef());
			return !!0;
		},
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
		return $meta->get_type('Overload') unless @_;
		
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
my $has_regexp_util;
my $serialize_regexp = sub {
	$has_regexp_util = eval {
		require Regexp::Util;
		Regexp::Util->VERSION('0.003');
		1;
	} || 0 unless defined $has_regexp_util;
	
	my $re = shift;
	my $serialized;
	if ($has_regexp_util) {
		$serialized = eval { Regexp::Util::serialize_regexp($re) };
	}
	
	if (!$serialized) {
		my $key = sprintf('%s|%s', ref($re), $re);
		$_StrMatch{$key} = $re;
		$serialized = sprintf('$Types::Standard::_StrMatch{%s}', B::perlstring($key));
	}
	
	return $serialized;
};
$meta->add_type({
	name       => "StrMatch",
	parent     => $_str,
	constraint_generator => sub
	{
		return $meta->get_type('StrMatch') unless @_;
		
		my ($regexp, $checker) = @_;
		
		$_regexp->check($regexp)
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
		if ($checker)
		{
			return unless $checker->can_be_inlined;
			
			my $serialized_re = $regexp->$serialize_regexp;
			return sub
			{
				my $v = $_[1];
				sprintf
					"!ref($v) and do { my \$m = [$v =~ %s]; %s }",
					$serialized_re,
					$checker->inline_check('$m'),
				;
			};
		}
		else
		{
			my $regexp_string = "$regexp";
			if ($regexp_string =~ /\A\(\?\^u?:(\.+)\)\z/) {
				my $length = length $1;
				return sub { "!ref($_) and length($_)>=$length" };
			}
			
			if ($regexp_string =~ /\A\(\?\^u?:\\A(\.+)\\z\)\z/) {
				my $length = length $1;
				return sub { "!ref($_) and length($_)==$length" };
			}
			
			my $serialized_re = $regexp->$serialize_regexp;
			return sub
			{
				my $v = $_[1];
				"!ref($v) and $v =~ $serialized_re";
			};
		}
	},
});

$meta->add_type({
	name       => "OptList",
	parent     => $_arr,
	constraint => sub {
		for my $inner (@$_) {
			return unless ref($inner) eq q(ARRAY);
			return unless @$inner == 2;
			return unless is_Str($inner->[0]);
		}
		return !!1;
	},
	inlined     => sub {
		my ($self, $var) = @_;
		my $Str_check = Str()->inline_check('$inner->[0]');
		my @code = 'do { my $ok = 1; ';
		push @code,   sprintf('for my $inner (@{%s}) { no warnings; ', $var);
		push @code,   sprintf('($ok=0) && last unless ref($inner) eq q(ARRAY) && @$inner == 2 && (%s); ', $Str_check);
		push @code,   '} ';
		push @code, '$ok }';
		return (undef, join(q( ), @code));
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
		return $meta->get_type('Tied') unless @_;
		
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
		return $meta->get_type('InstanceOf') unless @_;
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
		return $meta->get_type('ConsumerOf') unless @_;
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
		return $meta->get_type('HasMethods') unless @_;
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
		return $meta->get_type('Enum') unless @_;
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
		$_arr,    q{ Exporter::Tiny::mkopt($_) },
		$_hash,   q{ Exporter::Tiny::mkopt($_) },
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

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=for stopwords booleans vstrings typeglobs

=encoding utf-8

=for stopwords datetimes

=head1 NAME

Types::Standard - bundled set of built-in types for Type::Tiny

=head1 STATUS

This module is covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

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

Other customers also bought: C<< StringLike >> from L<Types::TypeTiny>.

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

Other customers also bought: C<< ArrayLike >> from L<Types::TypeTiny>.

=item C<< HashRef[`a] >>

A value where C<< ref($value) eq "HASH" >>.

If parameterized, the values of the hash must pass the additional
constraint. For example, C<< HashRef[Num] >> must be a reference to an
hash where the values are numbers. The hash keys are not constrained,
but Perl limits them to strings; see C<Map> below if you need to further
constrain the hash values.

Other customers also bought: C<< HashLike >> from L<Types::TypeTiny>.

=item C<< CodeRef >>

A value where C<< ref($value) eq "CODE" >>.

Other customers also bought: C<< CodeLike >> from L<Types::TypeTiny>.

=item C<< RegexpRef >>

A reference where C<< re::is_regexp($value) >> is true, or
a blessed reference where C<< $value->isa("Regexp") >> is true.

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

Subtype of C<ArrayRef>, accepting a list of type constraints for
each slot in the array.

C<< Tuple[Int, HashRef] >> would match C<< [1, {}] >> but not C<< [{}, 1] >>.

=item C<< Dict[...] >>

Subtype of C<HashRef>, accepting a list of type constraints for
each slot in the hash.

For example C<< Dict[name => Str, id => Int] >> allows
C<< { name => "Bob", id => 42 } >>.

=item C<< Optional[`a] >>

Used in conjunction with C<Dict> and C<Tuple> to specify slots that are
optional and may be omitted (but not necessarily set to an explicit undef).

C<< Dict[name => Str, id => Optional[Int]] >> allows C<< { name => "Bob" } >>
but not C<< { name => "Bob", id => "BOB" } >>.

Note that any use of C<< Optional[`a] >> outside the context of
parameterized C<Dict> and C<Tuple> type constraints makes little sense,
and its behaviour is undefined. (An exception: it is used by
L<Type::Params> for a similar purpose to how it's used in C<Tuple>.)

=back

This module also exports a C<slurpy> function, which can be used as
follows.

It can cause additional trailing values in a C<Tuple> to be slurped
into a structure and validated. For example, slurping into an ArrayRef:

   my $type = Tuple[Str, slurpy ArrayRef[Int]];
   
   $type->( ["Hello"] );                # ok
   $type->( ["Hello", 1, 2, 3] );       # ok
   $type->( ["Hello", [1, 2, 3]] );     # not ok

Or into a hashref:

   my $type2 = Tuple[Str, slurpy Map[Int, RegexpRef]];
   
   $type2->( ["Hello"] );                               # ok
   $type2->( ["Hello", 1, qr/one/i, 2, qr/two/] );      # ok

It can cause additional values in a C<Dict> to be slurped into a
hashref and validated:

   my $type3 = Dict[ values => ArrayRef, slurpy HashRef[Str] ];
   
   $type3->( { values => [] } );                        # ok
   $type3->( { values => [], name => "Foo" } );         # ok
   $type3->( { values => [], name => [] } );            # not ok

In either C<Tuple> or C<Dict>, C<< slurpy Any >> can be used to indicate
that additional values are acceptable, but should not be constrained in
any way. 

C<< slurpy Any >> is an optimized code path. Although the following are
essentially equivalent checks, the former should run a lot faster:

   Tuple[Int, slurpy Any]
   Tuple[Int, slurpy ArrayRef]

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

On certain versions of Perl, type constraints of the forms
C<< StrMatch[qr/../ >> and C<< StrMatch[qr/\A..\z/ >> with any number
of intervening dots can be optimized to simple length checks.

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

=item C<< CycleTuple[`a] >>

Similar to Tuple, but cyclical.

   CycleTuple[Int, HashRef]

will allow C<< [1,{}] >> and C<< [1,{},2,{}] >> but disallow
C<< [1,{},2] >> and C<< [1,{},2,[]] >>.

I think you understand CycleTuples already.

Currently C<Optional> and C<slurpy> parameters are forbidden. There are
fairly limited use cases for them, and it's not exactly clear what they
should mean.

The following is an efficient way of checking for an even-sized arrayref:

   CycleTuple[Any, Any]

The following is an arrayref which would be suitable for coercing to a
hashref:

   CycleTuple[Str, Any]

All the examples so far have used two parameters, but the following is
also a possible CycleTuple:

   CycleTuple[Str, Int, HashRef]

This will be an arrayref where the 0th, 3rd, 6th, etc values are
strings, the 1st, 4th, 7th, etc values are integers, and the 2nd,
5th, 8th, etc values are hashrefs.

=back

=head2 Coercions

None of the types in this type library have any coercions by default.
However some standalone coercions may be exported. These can be combined
with type constraints using the C<< plus_coercions >> method.

=over

=item C<< MkOpt >>

A coercion from C<ArrayRef>, C<HashRef> or C<Undef> to C<OptList>. Example
usage in a Moose attribute:

   use Types::Standard qw( OptList MkOpt );
   
   has options => (
      is     => "ro",
      isa    => OptList->plus_coercions( MkOpt ),
      coerce => 1,
   );

=item C<< Split[`a] >>

Split a string on a regexp.

   use Types::Standard qw( ArrayRef Str Split );
   
   has name => (
      is     => "ro",
      isa    => (ArrayRef[Str])->plus_coercions(Split[qr/\s/]),
      coerce => 1,
   );

=item C<< Join[`a] >>

Join an array of strings with a delimiter.

   use Types::Standard qw( Str Join );
   
   my $FileLines = Str->plus_coercions(Join["\n"]);
   
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

=item LazyLoad

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

L<Types::Common::Numeric> and L<Types::Common::String> provide replacements
for L<MooseX::Types::Common>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

