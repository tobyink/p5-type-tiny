package Type::Params;

use 5.006001;
use strict;
use warnings;

BEGIN {
	if ($] < 5.008) { require Devel::TypeTiny::Perl56Compat };
}

BEGIN {
	$Type::Params::AUTHORITY = 'cpan:TOBYINK';
	$Type::Params::VERSION   = '1.004002';
}

use B qw();
use Eval::TypeTiny;
use Scalar::Util qw(refaddr);
use Error::TypeTiny;
use Error::TypeTiny::Assertion;
use Error::TypeTiny::WrongNumberOfParameters;
use Types::Standard -types;
use Types::TypeTiny qw(CodeLike TypeTiny ArrayLike to_TypeTiny);

require Exporter::Tiny;
our @ISA = 'Exporter::Tiny';

our @EXPORT    = qw( compile compile_named );
our @EXPORT_OK = qw( multisig validate validate_named compile_named_oo Invocant );

sub english_list {
	require Type::Utils;
	goto \&Type::Utils::english_list;
}

my $QUOTE = ($^V < 5.010 && exists(&B::cstring))
	? \&B::cstring
	: \&B::perlstring;   # is buggy on Perl 5.8

{
	my $Invocant;
	sub Invocant () {
		$Invocant ||= do {
			require Type::Tiny::Union;
			require Types::Standard;
			'Type::Tiny::Union'->new(
				name             => 'Invocant',
				type_constraints => [
					Types::Standard::Object(),
					Types::Standard::ClassName(),
				],
			);
		};
	}
}

sub _mkslurpy
{
	my ($name, $type, $tc, $i) = @_;
	$name = 'local $_' if $name eq '$_';
	
	$type eq '@'
		? sprintf(
			'%s = [ @_[%d..$#_] ];',
			$name,
			$i,
		)
		: sprintf(
			'%s = (($#_-%d)%%2)==0 ? "Error::TypeTiny::WrongNumberOfParameters"->throw(message => sprintf("Odd number of elements in %%s", %s)) : +{ @_[%d..$#_] };',
			$name,
			$i,
			$QUOTE->("$tc"),
			$i,
		);
}

sub _mkdefault
{
	my $param_options = shift;
	my $default;
	
	if (exists $param_options->{default}) {
		$default = $param_options->{default};
		if (ArrayRef->check($default) and not @$default) {
			$default = '[]';
		}
		elsif (HashRef->check($default) and not %$default) {
			$default = '{}';
		}
		elsif (Str->check($default)) {
			$default = $QUOTE->($default);
		}
		elsif (Undef->check($default)) {
			$default = 'undef';
		}
		elsif (not CodeLike->check($default)) {
			Error::TypeTiny::croak("Default expected to be string, coderef, undef, or reference to an empty hash or array");
		}
	}

	$default;
}

sub compile
{
	my (@code, %env);
	push @code, '#placeholder', '#placeholder';  # @code[0,1]
	
	my %options;
	while (ref($_[0]) eq "HASH" && !$_[0]{slurpy}) {
		%options = (%options, %{+shift});
	}
	my $arg        = -1;
	my $saw_slurpy = 0;
	my $min_args   = 0;
	my $max_args   = 0;
	my $saw_opt    = 0;
	
	my $return_default_list = !!1;
	$code[0] = 'my (%tmp, $tmp);';
	PARAM: for my $param (@_) {
		if (HashRef->check($param)) {
			$code[0] = 'my (@R, %tmp, $tmp, $dtmp);';
			$return_default_list = !!0;
			last PARAM;
		}
		elsif (not Bool->check($param)) {
			if ($param->has_coercion) {
				$code[0] = 'my (@R, %tmp, $tmp, $dtmp);';
				$return_default_list = !!0;
				last PARAM;
			}
		}
	}
	
	my @default_indices;
	my @default_values;
		
	while (@_)
	{
		++$arg;
		my $constraint = shift;
		my $is_optional;
		my $really_optional;
		my $is_slurpy;
		my $varname;
		
		my $param_options = {};
		$param_options = shift if HashRef->check($_[0]) && !exists $_[0]{slurpy};
		my $default = _mkdefault($param_options);
		
		if ($param_options->{optional} or defined $default) {
			$is_optional = 1;
		}
		
		if (Bool->check($constraint))
		{
			$constraint = $constraint ? Any : Optional[Any];
		}

		if (HashRef->check($constraint) and exists $constraint->{slurpy})
		{
			$constraint = to_TypeTiny(
				$constraint->{slurpy}
					or Error::TypeTiny::croak("Slurpy parameter malformed")
			);
			push @code,
				$constraint->is_a_type_of(Dict)     ? _mkslurpy('$_', '%', $constraint => $arg) :
				$constraint->is_a_type_of(Map)      ? _mkslurpy('$_', '%', $constraint => $arg) :
				$constraint->is_a_type_of(Tuple)    ? _mkslurpy('$_', '@', $constraint => $arg) :
				$constraint->is_a_type_of(HashRef)  ? _mkslurpy('$_', '%', $constraint => $arg) :
				$constraint->is_a_type_of(ArrayRef) ? _mkslurpy('$_', '@', $constraint => $arg) :
				Error::TypeTiny::croak("Slurpy parameter not of type HashRef or ArrayRef");
			$varname = '$_';
			$is_slurpy++;
			$saw_slurpy++;
		}
		else
		{
			Error::TypeTiny::croak("Parameter following slurpy parameter") if $saw_slurpy;
			
			$is_optional     += grep $_->{uniq} == Optional->{uniq}, $constraint->parents;
			$really_optional = $is_optional && $constraint->parent && $constraint->parent->{uniq} eq Optional->{uniq} && $constraint->type_parameter;
			
			if (ref $default) {
				$env{'@default'}[$arg] = $default;
				push @code, sprintf(
					'$dtmp = ($#_ < %d) ? $default[%d]->() : $_[%d];',
					$arg,
					$arg,
					$arg,
				);
				$saw_opt++;
				$max_args++;
				$varname = '$dtmp';
			}
			elsif (defined $default) {
				push @code, sprintf(
					'$dtmp = ($#_ < %d) ? %s : $_[%d];',
					$arg,
					$default,
					$arg,
				);
				$saw_opt++;
				$max_args++;
				$varname = '$dtmp';
			}
			elsif ($is_optional)
			{
				push @code, sprintf(
					'return %s if $#_ < %d;',
					$return_default_list ? '@_' : '@R',
					$arg,
				);
				$saw_opt++;
				$max_args++;
				$varname = sprintf '$_[%d]', $arg;
			}
			else
			{
				Error::TypeTiny::croak("Non-Optional parameter following Optional parameter") if $saw_opt;
				$min_args++;
				$max_args++;
				$varname = sprintf '$_[%d]', $arg;
			}
		}
		
		if ($constraint->has_coercion and $constraint->coercion->can_be_inlined)
		{
			push @code, sprintf(
				'$tmp%s = %s;',
				($is_optional ? '{x}' : ''),
				$constraint->coercion->inline_coercion($varname)
			);
			$varname = '$tmp'.($is_optional ? '{x}' : '');
		}
		elsif ($constraint->has_coercion)
		{
			$env{'@coerce'}[$arg] = $constraint->coercion->compiled_coercion;
			push @code, sprintf(
				'$tmp%s = $coerce[%d]->(%s);',
				($is_optional ? '{x}' : ''),
				$arg,
				$varname,
			);
			$varname = '$tmp'.($is_optional ? '{x}' : '');
		}
		
		if ($constraint->can_be_inlined)
		{
			push @code, sprintf(
				'(%s) or Type::Tiny::_failed_check(%d, %s, %s, varname => %s);',
				$really_optional
					? $constraint->type_parameter->inline_check($varname)
					: $constraint->inline_check($varname),
				$constraint->{uniq},
				$QUOTE->($constraint),
				$varname,
				$is_slurpy ? 'q{$SLURPY}' : sprintf('q{$_[%d]}', $arg),
			);
		}
		else
		{
			$env{'@check'}[$arg] = $really_optional
				? $constraint->type_parameter->compiled_check
				: $constraint->compiled_check;
			push @code, sprintf(
				'%s or Type::Tiny::_failed_check(%d, %s, %s, varname => %s);',
				sprintf(sprintf '$check[%d]->(%s)', $arg, $varname),
				$constraint->{uniq},
				$QUOTE->($constraint),
				$varname,
				$is_slurpy ? 'q{$SLURPY}' : sprintf('q{$_[%d]}', $arg),
			);
		}
		
		unless ($return_default_list) {
			push @code, sprintf 'push @R, %s;', $varname;
		}
	}
	
	if ($min_args == $max_args and not $saw_slurpy)
	{
		$code[1] = sprintf(
			'"Error::TypeTiny::WrongNumberOfParameters"->throw(got => scalar(@_), minimum => %d, maximum => %d) if @_ != %d;',
			$min_args,
			$max_args,
			$min_args,
		);
	}
	elsif ($min_args < $max_args and not $saw_slurpy)
	{
		$code[1] = sprintf(
			'"Error::TypeTiny::WrongNumberOfParameters"->throw(got => scalar(@_), minimum => %d, maximum => %d) if @_ < %d || @_ > %d;',
			$min_args,
			$max_args,
			$min_args,
			$max_args,
		);
	}
	elsif ($min_args and $saw_slurpy)
	{
		$code[1] = sprintf(
			'"Error::TypeTiny::WrongNumberOfParameters"->throw(got => scalar(@_), minimum => %d) if @_ < %d;',
			$min_args,
			$min_args,
		);
	}
	
	if ($return_default_list) {
		push @code, '@_;';
	}
	else {
		push @code, '@R;';
	}
	
	my $source  = "sub { no warnings; ".join("\n", @code)." };";
	
	return $source if $options{want_source};
	
	my $closure = eval_closure(
		source      => $source,
		description => $options{description}||sprintf("parameter validation for '%s'", $options{subname}||[caller(1+($options{caller_level}||0))]->[3] || '__ANON__'),
		environment => \%env,
	);
	
	return {
		min_args    => $min_args,
		max_args    => $saw_slurpy ? undef : $max_args,
		closure     => $closure,
		source      => $source,
		environment => \%env,
	} if $options{want_details};
	
	return $closure;
}

sub compile_named
{
	my (@code, %env);
	
	@code = 'my (%R, %tmp, $tmp);';
	push @code, '#placeholder';   # $code[1]
	
	my %options;
	while (ref($_[0]) eq "HASH" && !$_[0]{slurpy}) {
		%options = (%options, %{+shift});
	}
	my $arg = -1;
	my $had_slurpy;
	
	push @code, 'my %in = ((@_==1) && ref($_[0]) eq "HASH") ? %{$_[0]} : (@_ % 2) ? "Error::TypeTiny::WrongNumberOfParameters"->throw(message => "Odd number of elements in hash") : @_;';
	
	while (@_) {
		++$arg;
		my ($name, $constraint) = splice(@_, 0, 2);
		
		my $is_optional;
		my $really_optional;
		my $is_slurpy;
		my $varname;
		my $default;
		
		Str->check($name)
			or Error::TypeTiny::croak("Expected parameter name as string, got $name");
		
		my $param_options = {};
		$param_options = shift @_ if HashRef->check($_[0]) && !exists $_[0]{slurpy};
		$default = _mkdefault($param_options);
		
		if ($param_options->{optional} or defined $default) {
			$is_optional = 1;
		}
	
		if (Bool->check($constraint))
		{
			$constraint = $constraint ? Any : Optional[Any];
		}
	
		if (HashRef->check($constraint) and exists $constraint->{slurpy})
		{
			$constraint = to_TypeTiny($constraint->{slurpy});
			++$is_slurpy;
			++$had_slurpy;
		}
		else
		{
			$is_optional     += grep $_->{uniq} == Optional->{uniq}, $constraint->parents;
			$really_optional = $is_optional && $constraint->parent && $constraint->parent->{uniq} eq Optional->{uniq} && $constraint->type_parameter;
			
			$constraint = $constraint->type_parameter if $really_optional;
		}
		
		if (ref $default) {
			$env{'@default'}[$arg] = $default;
			push @code, sprintf(
				'exists($in{%s}) or $in{%s} = $default[%d]->();',
				$QUOTE->($name),
				$QUOTE->($name),
				$arg,
			);
		}
		elsif (defined $default) {
			push @code, sprintf(
				'exists($in{%s}) or $in{%s} = %s;',
				$QUOTE->($name),
				$QUOTE->($name),
				$default,
			);
		}
		elsif (not $is_optional||$is_slurpy) {
			push @code, sprintf(
				'exists($in{%s}) or "Error::TypeTiny::WrongNumberOfParameters"->throw(message => sprintf "Missing required parameter: %%s", %s);',
				$QUOTE->($name),
				$QUOTE->($name),
			);
		}
		
		my $need_to_close_if = 0;
		
		if ($is_slurpy) {
			$varname = '\\%in';
		}
		elsif ($is_optional) {
			push @code, sprintf('if (exists($in{%s})) {', $QUOTE->($name));
			push @code, sprintf('$tmp = delete($in{%s});', $QUOTE->($name));
			$varname = '$tmp';
			++$need_to_close_if;
		}
		else {
			push @code, sprintf('$tmp = delete($in{%s});', $QUOTE->($name));
			$varname = '$tmp';
		}
		
		if ($constraint->has_coercion) {
			if ($constraint->coercion->can_be_inlined) {
				push @code, sprintf(
					'$tmp = %s;',
					$constraint->coercion->inline_coercion($varname)
				);
			}
			else {
				$env{'@coerce'}[$arg] = $constraint->coercion->compiled_coercion;
				push @code, sprintf(
					'$tmp = $coerce[%d]->(%s);',
					$arg,
					$varname,
				);
			}
			$varname = '$tmp';
		}
		
		if ($constraint->can_be_inlined)
		{
			push @code, sprintf(
				'(%s) or Type::Tiny::_failed_check(%d, %s, %s, varname => %s);',
				$constraint->inline_check($varname),
				$constraint->{uniq},
				$QUOTE->($constraint),
				$varname,
				$is_slurpy ? 'q{$SLURPY}' : sprintf('q{$_{%s}}', $QUOTE->($name)),
			);
		}
		else
		{
			$env{'@check'}[$arg] = $constraint->compiled_check;
			push @code, sprintf(
				'%s or Type::Tiny::_failed_check(%d, %s, %s, varname => %s);',
				sprintf(sprintf '$check[%d]->(%s)', $arg, $varname),
				$constraint->{uniq},
				$QUOTE->($constraint),
				$varname,
				$is_slurpy ? 'q{$SLURPY}' : sprintf('q{$_{%s}}', $QUOTE->($name)),
			);
		}
		
		push @code, sprintf('$R{%s} = %s;', $QUOTE->($name), $varname);
		
		push @code, '}' if $need_to_close_if;
	}
	
	if (!$had_slurpy) {
		push @code, 'keys(%in) and "Error::TypeTiny"->throw(message => sprintf "Unrecognized parameter%s: %s", keys(%in)>1?"s":"", Type::Params::english_list(sort keys %in));'
	}
	
	if ($options{bless}) {
		push @code, sprintf('bless \\%%R, %s;', $QUOTE->($options{bless}));
	}
	elsif (ArrayRef->check($options{class})) {
		push @code, sprintf('(%s)->%s(\\%%R);', $QUOTE->($options{class}[0]), $options{class}[1]||'new');
	}
	elsif ($options{class}) {
		push @code, sprintf('(%s)->%s(\\%%R);', $QUOTE->($options{class}), $options{constructor}||'new');
	}
	else {
		push @code, '\\%R;';
	}
	
	my $source  = "sub { no warnings; ".join("\n", @code)." };";
	return $source if $options{want_source};
	
	my $closure = eval_closure(
		source      => $source,
		description => $options{description}||sprintf("parameter validation for '%s'", $options{subname}||[caller(1+($options{caller_level}||0))]->[3] || '__ANON__'),
		environment => \%env,
	);
	
	return {
		min_args    => undef,  # always going to be 1 or 0
		max_args    => undef,  # should be possible to figure out if no slurpy param
		closure     => $closure,
		source      => $source,
		environment => \%env,
	} if $options{want_details};
	
	return $closure;
}

my %klasses;
my $kls_id = 0;
my $has_cxsa;
my $want_cxsa;
sub _mkklass
{
	my $klass = sprintf('%s::OO::Klass%d', __PACKAGE__, ++$kls_id);
	
	if (!defined $has_cxsa or !defined $want_cxsa) {
		$has_cxsa = !! eval {
			require Class::XSAccessor;
			'Class::XSAccessor'->VERSION('1.17'); # exists_predicates, June 2013
			1;
		};
		
		$want_cxsa =
			$ENV{PERL_TYPE_PARAMS_XS}         ? 'XS' :
			exists($ENV{PERL_TYPE_PARAMS_XS}) ? 'PP' :
			$has_cxsa                         ? 'XS' : 'PP';
		
		if ($want_cxsa eq 'XS' and not $has_cxsa) {
			Error::TypeTiny::croak("Cannot load Class::XSAccessor"); # uncoverable statement
		}
	}
	
	if ($want_cxsa eq 'XS') {
		eval {
			'Class::XSAccessor'->import(
				redefine          => 1,
				class             => $klass,
				getters           => { map { defined($_->{getter})    ? ($_->{getter}    => $_->{slot}) : () } values %{$_[0]} },
				exists_predicates => { map { defined($_->{predicate}) ? ($_->{predicate} => $_->{slot}) : () } values %{$_[0]} },
			);
			1;
		} ? return($klass) : die($@);
	}
	
	for my $attr (values %{$_[0]}) {
		defined($attr->{getter}) and eval sprintf(
			'package %s; sub %s { $_[0]{%s} }; 1',
			$klass,
			$attr->{getter},
			$attr->{slot},
		) || die($@);
		defined($attr->{predicate}) and eval sprintf(
			'package %s; sub %s { exists $_[0]{%s} }; 1',
			$klass,
			$attr->{predicate},
			$attr->{slot},
		) || die($@);
	}
	
	$klass;
}

sub compile_named_oo
{
	my %options;
	while (ref($_[0]) eq "HASH" && !$_[0]{slurpy}) {
		%options = (%options, %{+shift});
	}
	my @rest       = @_;
	
	my %attribs;
	while (@_) {
		my ($name, $type) = splice(@_, 0, 2);
		my $opts = (HashRef->check($_[0]) && !exists $_[0]{slurpy}) ? shift(@_) : {};
			
		my $is_optional = 0+!! $opts->{optional};
		$is_optional += grep $_->{uniq} == Optional->{uniq}, $type->parents;
		
		my $getter = exists($opts->{getter})
			? $opts->{getter}
			: $name;
		
		Error::TypeTiny::croak("Bad accessor name: $getter")
			unless $getter =~ /\A[A-Za-z][A-Za-z0-9_]*\z/;
		
		my $predicate = exists($opts->{predicate})
			? ($opts->{predicate} eq '1' ? "has_$getter" : $opts->{predicate} eq '0' ? undef : $opts->{predicate})
			: ($is_optional ? "has_$getter" : undef);
		
		$attribs{$name} = {
			slot       => $name,
			getter     => $getter,
			predicate  => $predicate,
		};
	}
	
	my $kls = join '//',
		map sprintf('%s*%s*%s', $attribs{$_}{slot}, $attribs{$_}{getter}, $attribs{$_}{predicate}||'0'),
		sort keys %attribs;
	
	$klasses{$kls} ||= _mkklass(\%attribs);
	
	compile_named({ %options, bless => $klasses{$kls} }, @rest);
}

# Would be faster to inline this into validate and validate_named, but
# that would complicate them. :/
sub _mk_key {
	local $_;
	join ':', map {
		HashRef->check($_)   ? do { my %h = %$_; sprintf('{%s}', _mk_key(map {; $_ => $h{$_} } sort keys %h)) } :
		TypeTiny->check($_)  ? sprintf('TYPE=%s', $_->{uniq}) :
		Ref->check($_)       ? sprintf('REF=%s', refaddr($_)) :
		Undef->check($_)     ? sprintf('UNDEF') :
		$QUOTE->($_)
	} @_;
}

my %compiled;
sub validate
{
	my $arg = shift;
	my $sub = ($compiled{_mk_key(@_)} ||= compile(
		{ caller_level => 1, %{ref($_[0])eq'HASH'?shift(@_):+{}} },
		@_,
	));
	@_ = @$arg;
	goto $sub;
}

my %compiled_named;
sub validate_named
{
	my $arg = shift;
	my $sub = ($compiled_named{_mk_key(@_)} ||= compile_named(
		{ caller_level => 1, %{ref($_[0])eq'HASH'?shift(@_):+{}} },
		@_,
	));
	@_ = @$arg;
	goto $sub;
}

sub multisig
{
	my %options = (ref($_[0]) eq "HASH" && !$_[0]{slurpy}) ? %{+shift} : ();
	my @multi = map {
		CodeLike->check($_)  ? { closure => $_ } :
		ArrayLike->check($_) ? compile({ want_details => 1 }, @$_) :
		$_;
	} @_;
	
	my @code = 'sub { my $r; ';
	
	for my $i (0 .. $#multi)
	{
		my $flag = sprintf('${^TYPE_PARAMS_MULTISIG} = %d', $i);
		my $sig  = $multi[$i];
		my @cond;
		push @cond, sprintf('@_ >= %s', $sig->{min_args}) if defined $sig->{min_args};
		push @cond, sprintf('@_ <= %s', $sig->{max_args}) if defined $sig->{max_args};
		if (defined $sig->{max_args} and defined $sig->{min_args}) {
			@cond = sprintf('@_ == %s', $sig->{min_args})
				if $sig->{max_args} == $sig->{min_args};
		}
		push @code, sprintf('if (%s){', join(' and ', @cond)) if @cond;
		push @code, sprintf('eval { $r = [ $multi[%d]{closure}->(@_) ]; %s };', $i, $flag);
		push @code, 'return(@$r) if $r;';
		push @code, '}' if @cond;
	}
	
	push @code, '"Error::TypeTiny"->throw(message => "Parameter validation failed");';
	push @code, '}';
	
	eval_closure(
		source      => \@code,
		description => sprintf("parameter validation for '%s'", [caller(1+($options{caller_level}||0))]->[3] || '__ANON__'),
		environment => { '@multi' => \@multi },
	);
}

1;

__END__

=pod

=encoding utf-8

=for stopwords evals invocant

=head1 NAME

Type::Params - Params::Validate-like parameter validation using Type::Tiny type constraints and coercions

=head1 SYNOPSIS

 use v5.10;
 use strict;
 use warnings;
 
 use Type::Params qw( compile );
 use Types::Standard qw( slurpy Str ArrayRef Num );
   
 sub deposit_monies
 {
    state $check = compile( Str, Str, slurpy ArrayRef[Num] );
    my ($sort_code, $account_number, $monies) = $check->(@_);
    
    my $account = Local::BankAccount->new($sort_code, $account_number);
    $account->deposit($_) for @$monies;
 }
 
 deposit_monies("12-34-56", "11223344", 1.2, 3, 99.99);

=head1 STATUS

This module is covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

Type::Params uses L<Type::Tiny> constraints to validate the parameters to a
sub. It takes the slightly unorthodox approach of separating validation
into two stages:

=over

=item 1.

Compiling the parameter specification into a coderef; then

=item 2.

Using the coderef to validate parameters.

=back

The first stage is slow (it might take a couple of milliseconds), but you
only need to do it the first time the sub is called. The second stage is
fast; according to my benchmarks faster even than the XS version of
L<Params::Validate>.

If you're using a modern version of Perl, you can use the C<state> keyword
which was a feature added to Perl in 5.10. If you're stuck on Perl 5.8, the
example from the SYNOPSIS could be rewritten as:

 my $deposit_monies_check;
 sub deposit_monies
 {
    $deposit_monies_check ||= compile( Str, Str, slurpy ArrayRef[Num] );
    my ($sort_code, $account_number, $monies) = $deposit_monies_check->(@_);
    
    ...;
 }

Not quite as neat, but not awful either.

There's a shortcut reducing it to one step:

 use Type::Params qw( validate );
 
 sub deposit_monies
 {
    my ($sort_code, $account_number, $monies) = 
       validate( \@_, Str, Str, slurpy ArrayRef[Num] );
    
    ...;
 }

Type::Params has a few tricks up its sleeve to make sure performance doesn't
suffer too much with the shortcut, but it's never going to be as fast as the
two stage compile/execute.

=begin trustme

Dude, these functions are documented!

=item compile

=item validate

=item compile_named

=item validate_named

=item compile_named_oo

=item Invocant

=item multisig

=end trustme

=head1 VALIDATE VERSUS COMPILE

This module offers one-stage ("validate") and two-stage ("compile" then
"check") variants of parameter checking for you to use. Performance with
the two-stage variant will I<always> beat the one stage variant — I
cannot think of many reasons you'd want to use the one-stage version.

 # One-stage, positional parameters
 my @args = validate(\@_, @spec);
 
 # Two-stage, positional parameters
 state $check = compile(@spec);
 my @args = $check->(@_);
 
 # One-stage, named parameters
 my $args = validate_named(\@_, @spec);
 
 # Two-stage, named parameters
 state $check = compile_named(@spec);
 my $args = $check->(@_);

Use C<compile> and C<compile_named>, not C<validate> and C<validate_named>.

=head1 VALIDATION SPECIFICATIONS

The C<< @spec >> is where most of the magic happens.

The generalized form of specifications for positional parameters is:

 @spec = (
   \%general_opts,
   $type_for_arg_1, \%opts_for_arg_1,
   $type_for_arg_2, \%opts_for_arg_2,
   $type_for_arg_3, \%opts_for_arg_3,
   ...,
   slurpy($slurpy_type),
 );

And for named parameters:

 @spec = (
   \%general_opts,
   foo => $type_for_foo, \%opts_for_foo,
   bar => $type_for_bar, \%opts_for_bar,
   baz => $type_for_baz, \%opts_for_baz,
   ...,
   slurpy($slurpy_type),
 );

Option hashrefs can simply be omitted if you don't need to specify any
particular options.

The C<slurpy> function is exported by L<Types::Standard>. It may be
omitted if not needed.

=head2 General Options

Currently supported general options are:

=over

=item C<< want_source => Bool >>

Instead of returning a coderef, return Perl source code string. Handy
for debugging.

=item C<< want_details => Bool >>

Instead of returning a coderef, return a hashref of stuff including the
coderef. This is mostly for people extending Type::Params and I won't go
into too many details about what else this hashref contains.

=item C<< class => ClassName >>

B<< Named parameters only. >> The check coderef will, instead of returning
a simple hashref, call C<< $class->new($hashref) >> and return a proper
object.

=item C<< constructor => Str >>

B<< Named parameters only. >> Specify an alternative method name instead
of C<new> for the C<class> option described above.

=item C<< class => Tuple[ClassName, Str] >>

B<< Named parameters only. >> Given a class name and constructor name pair,
the check coderef will, instead of returning a simple hashref, call
C<< $class->$constructor($hashref) >> and return a proper object. Shortcut
for declaring both the C<class> and C<constructor> options at once.

=item C<< bless => ClassName >>

B<< Named parameters only. >> Bypass the constructor entirely and directly
bless the hashref.

=item C<< description => Str >>

Description of the coderef that will show up in stack traces. Defaults to
"parameter validation for X" where X is the caller sub name.

=item C<< subname => Str >>

If you wish to use the default description, but need to change the sub name,
use this.

=item C<< caller_level => Int >>

If you wish to use the default description, but need to change the caller
level for detecting the sub name, use this.

=back

=head2 Type Constraints

The types for each parameter may be any L<Type::Tiny> type constraint, or
anything that Type::Tiny knows how to coerce into a Type::Tiny type
constraint, such as a MooseX::Types type constraint or a coderef.

=head2 Optional Parameters

The C<Optional> parameterizable type constraint from L<Types::Standard>
may be used to indicate optional parameters.

 # Positional parameters
 state $check = compile(Int, Optional[Int], Optional[Int]);
 my ($foo, $bar, $baz) = $check->(@_);  # $bar and $baz are optional
 
 # Named parameters
 state $check = compile(
   foo => Int,
   bar => Optional[Int],
   baz => Optional[Int],
 );
 my $args = $check->(@_);  # $args->{bar} and $args->{baz} are optional

As a special case, the numbers 0 and 1 may be used as shortcuts for
C<< Optional[Any] >> and C<< Any >>.

 # Positional parameters
 state $check = compile(1, 0, 0);
 my ($foo, $bar, $baz) = $check->(@_);  # $bar and $baz are optional
 
 # Named parameters
 state $check = compile_named(foo => 1, bar => 0, baz => 0);
 my $args = $check->(@_);  # $args->{bar} and $args->{baz} are optional

If you're using positional parameters, then required parameters must
precede any optional ones.

=head2 Slurpy Parameters

Specifications may include a single slurpy parameter which should have
a type constraint derived from C<ArrayRef> or C<HashRef>. (C<Any> is
also allowed, which is interpreted as C<ArrayRef> in the case of positional
parameters, and C<HashRef> in the case of named parameters.)

If a slurpy parameter is provided in the specification, the C<< $check >>
coderef will slurp up any remaining arguments from C<< @_ >> (after
required and optional parameters have been removed), validate it against
the given slurpy type, and return it as a single arrayref/hashref.

For example:

 sub xyz {
   state $check = compile(Int, Int, slurpy ArrayRef[Int]);
   my ($foo, $bar, $baz) = $check->(@_);
 }
 
 xyz(1..5);  # $foo = 1
             # $bar = 2
             # $baz = [ 3, 4, 5 ]

A specification have one or zero slurpy parameters. If there is a slurpy
parameter, it must be the final one.

Note that having a slurpy parameter will slightly slow down C<< $check >>
because it means that C<< $check >> can't just check C<< @_ >> and return
it unaltered if it's valid — it needs to build a new array to return.

=head2 Type Coercion

Type coercions are automatically applied for all types that have
coercions.

 my $RoundedInt = Int->plus_coercions(Num, q{ int($_) });
 
 state $check = compile($RoundedInt, $RoundedInt);
 my ($foo, $bar) = $check->(@_);
 
 # if @_ is (1.1, 2.2), then $foo is 1 and $bar is 2.

Coercions carry over into structured types such as C<ArrayRef> automatically:

 sub delete_articles
 {
   state $check = compile( Object, slurpy ArrayRef[$RoundedInt] );
   my ($db, $articles) = $check->(@_);
   
   $db->select_article($_)->delete for @$articles;
 }
 
 # delete articles 1, 2 and 3
 delete_articles($my_db, 1.1, 2.2, 3.3);

That's a L<Types::Standard> feature rather than something specific to
Type::Params.

Note that having any coercions in a specification, even if they're not
used in a particular check, will slightly slow down C<< $check >>
because it means that C<< $check >> can't just check C<< @_ >> and return
it unaltered if it's valid — it needs to build a new array to return.

=head2 Parameter Options

The type constraint for a parameter may be followed by a hashref of
options for it.

The following options are supported:

=over

=item C<< optional => Bool >>

This is an alternative way of indicating that a parameter is optional.

 state $check = compile_named(
   foo => Int,
   bar => Int, { optional => 1 },
   baz => Optional[Int],
 );

The two are not I<exactly> equivalent. If you were to set C<bar> to a
non-integer, it would throw an exception about the C<Int> type constraint
being violated. If C<baz> were a non-integer, the exception would mention
the C<< Optional[Int] >> type constraint instead.

=item C<< default => CodeRef|Ref|Str|Undef >>

A default may be provided for a parameter.

 state $check = compile_named(
   foo => Int,
   bar => Int, { default => "666" },
   baz => Int, { default => "999" },
 );

Supported defaults are any strings (including numerical ones), C<undef>,
and empty hashrefs and arrayrefs. Non-empty hashrefs and arrayrefs are
I<< not allowed as defaults >>.

Alternatively, you may provide a coderef to generate a default value:

 state $check = compile_named(
   foo => Int,
   bar => Int, { default => sub { 6 * 111 } },
   baz => Int, { default => sub { 9 * 111 } },
 );

That coderef may generate any value, including non-empty arrayrefs and
non-empty hashrefs. For undef, simple strings, numbers, and empty
structures, avoiding using a coderef will make your parameter processing
faster.

The default I<will> be validated against the type constraint, and
potentially coerced.

Defaults are not supported for slurpy parameters.

Note that having any defaults in a specification, even if they're not
used in a particular check, will slightly slow down C<< $check >>
because it means that C<< $check >> can't just check C<< @_ >> and return
it unaltered if it's valid — it needs to build a new array to return.

=back

=head1 MULTIPLE SIGNATURES

Type::Params can export a C<multisig> function that compiles multiple
alternative signatures into one, and uses the first one that works:

   state $check = multisig(
      [ Int, ArrayRef ],
      [ HashRef, Num ],
      [ CodeRef ],
   );
   
   my ($int, $arrayref) = $check->( 1, [] );      # okay
   my ($hashref, $num)  = $check->( {}, 1.1 );    # okay
   my ($code)           = $check->( sub { 1 } );  # okay
   
   $check->( sub { 1 }, 1.1 );  # throws an exception

Coercions, slurpy parameters, etc still work.

The magic global C<< ${^TYPE_PARAMS_MULTISIG} >> is set to the index of
the first signature which succeeded.

The present implementation involves compiling each signature independently,
and trying them each (in their given order!) in an C<eval> block. The only
slightly intelligent part is that it checks if C<< scalar(@_) >> fits into
the signature properly (taking into account optional and slurpy parameters),
and skips evals which couldn't possibly succeed.

It's also possible to list coderefs as alternatives in C<multisig>:

   state $check = multisig(
      [ Int, ArrayRef ],
      sub { ... },
      [ HashRef, Num ],
      [ CodeRef ],
      compile_named( needle => Value, haystack => Ref ),
   );

The coderef is expected to die if that alternative should be abandoned (and
the next alternative tried), or return the list of accepted parameters. Here's
a full example:

   sub get_from {
      state $check = multisig(
         [ Int, ArrayRef ],
         [ Str, HashRef ],
         sub {
            my ($meth, $obj);
            die unless is_Object($obj);
            die unless $obj->can($meth);
            return ($meth, $obj);
         },
      );
      
      my ($needle, $haystack) = $check->(@_);
      
      for (${^TYPE_PARAMS_MULTISIG) {
         return $haystack->[$needle] if $_ == 0;
         return $haystack->{$needle} if $_ == 1;
         return $haystack->$needle   if $_ == 2;
      }
   }
   
   get_from(0, \@array);      # returns $array[0]
   get_from('foo', \%hash);   # returns $hash{foo}
   get_from('foo', $obj);     # returns $obj->foo

=head1 PARAMETER OBJECTS

Here's a quick example function:

   sub add_contact_to_database {
      state $check = compile_named(
         dbh     => Object,
         id      => Int,
         name    => Str,
      );
      my $arg = $check->(@_);
      
      my $sth = $arg->{db}->prepare('INSERT INTO contacts VALUES (?, ?)');
      $sth->execute($arg->{id}, $arg->{name});
   }

Looks simple, right? Did you spot that it will always die with an error
message I<< Can't call method "prepare" on an undefined value >>?

This is because we defined a parameter called 'dbh' but later tried to
refer to it as C<< $arg{db} >>. Here, Perl gives us a pretty clear
error, but sometimes the failures will be far more subtle. Wouldn't it
be nice if instead we could do this?

   sub add_contact_to_database {
      state $check = compile_named_oo(
         dbh     => Object,
         id      => Int,
         name    => Str,
      );
      my $arg = $check->(@_);
      
      my $sth = $arg->dbh->prepare('INSERT INTO contacts VALUES (?, ?)');
      $sth->execute($arg->id, $arg->name);
   }

If we tried to call C<< $arg->db >>, it would fail because there was
no such method.

Well, that's exactly what C<compile_named_oo> does.

As well as giving you nice protection against mistyped parameter names,
It also looks kinda pretty, I think. Hash lookups are a little faster
than method calls, of course (though Type::Params creates the methods
using L<Class::XSAccessor> if it's installed, so they're still pretty
fast).

An optional parameter C<foo> will also get a nifty C<< $arg->has_foo >>
predicate method. Yay!

=head2 Options

C<compile_named_oo> gives you some extra options for parameters.

   sub add_contact_to_database {
      state $check = compile_named_oo(
         dbh     => Object,
         id      => Int,    { default => '0', getter => 'identifier' },
         name    => Str,    { optional => 1, predicate => 'has_name' },
      );
      my $arg = $check->(@_);
      
      my $sth = $arg->dbh->prepare('INSERT INTO contacts VALUES (?, ?)');
      $sth->execute($arg->identifier, $arg->name) if $arg->has_name;
   }

The C<getter> option lets you choose the method name for getting the
argument value. The C<predicate> option lets you choose the method name
for checking the existence of an argument.

By setting an explicit predicate method name, you can force a predicate
method to be generated for non-optional arguments.

=head2 Classes

The objects returned by C<compile_named_oo> are blessed into lightweight
classes which have been generated on the fly. Don't expect the names of
the classes to be stable or predictable. It's probably a bad idea to be
checking C<can>, C<isa>, or C<DOES> on any of these objects. If you're
doing that, you've missed the point of them.

They don't have any constructor (C<new> method). The C<< $check >>
coderef effectively I<is> the constructor.

=head1 COOKBOOK

=head2 Mixed Positional and Named Parameters

This can be faked using positional parameters and a slurpy dictionary.

 state $check = compile(
   Int,
   slurpy Dict[
     foo => Int,
     bar => Optional[Int],
     baz => Optional[Int],
   ],
 );
 
 @_ = (42, foo => 21);                 # ok
 @_ = (42, foo => 21, bar  => 84);     # ok
 @_ = (42, foo => 21, bar  => 10.5);   # not ok
 @_ = (42, foo => 21, quux => 84);     # not ok

=head2 Method Calls

Some people like to C<shift> off the invocant before running type checks:

 sub my_method {
   my $self = shift;
   state $check = compile_named(
     haystack => ArrayRef,
     needle   => Int,
   );
   my $arg = $check->(@_);
   
   return $arg->{haystack}[ $self->base_index + $arg->{needle} ];
 }
 
 $object->my_method(haystack => \@somelist, needle => 42);

If you're using positional parameters, there's really no harm in including
the invocant in the check:

 sub my_method {
   state $check = compile(Object, ArrayRef, Int);
   my ($self, $arr, $ix) = $check->(@_);
   
   return $arr->[ $self->base_index + $ix ];
 }
 
 $object->my_method(\@somelist, 42);

Some methods will be designed to be called as class methods rather than
instance methods. Remember to use C<ClassName> instead of C<Object> in
those cases.

Type::Params exports an additional keyword C<Invocant> on request. This
gives you a type constraint which accepts classnames I<and> blessed
objects.

 use Type::Params qw( compile Invocant );
 
 sub my_method {
   state $check = compile(Instance, ArrayRef, Int);
   my ($self_or_class, $arr, $ix) = $check->(@_);
   
   return $arr->[ $ix ];
 }

=head2 There is no C<< coerce => 0 >>

If you give C<compile> a type constraint which has coercions, then
C<< $check >> will I<< always coerce >>. It cannot be switched off.

Luckily, Type::Tiny gives you a very easy way to create a type
constraint without coercions from one that has coercions:

 state $check = compile(
   $RoundedInt->no_coercions,
   $RoundedInt->minus_coercions(Num),
 );

That's a Type::Tiny feature rather than a Type::Params feature though.

=head2 Extra Coercions

Type::Tiny provides an easy shortcut for adding coercions to
a type constraint:

 # We want an arrayref, but accept a hashref and coerce it
 state $check => compile(
   ArrayRef->plus_coercions( HashRef, sub { [sort values %$_] } ),
 );

=head2 Value Constraints

You may further constrain a parameter using C<where>:

 state $check = compile(
   Int->where('$_ % 2 == 0'),   # even numbers only
 );

This is also a Type::Tiny feature rather than a Type::Params feature.

=head2 Smarter Defaults

This works:

 sub print_coloured {
   state $check = compile(
     Str,
     Str, { default => "black" },
   );
   
   my ($text, $colour) = $check->(@_);
   
   ...;
 }

But so does this (and it might benchmark a little faster):

 sub print_coloured {
   state $check = compile(
     Str,
     Str, { optional => 1 },
   );
   
   my ($text, $colour) = $check->(@_);
   $colour = "black" if @_ < 2;
   
   ...;
 }

Just because Type::Params now supports defaults, doesn't mean you can't
do it the old-fashioned way. The latter is more flexible. In the example,
we've used C<< if @_ < 2 >>, but we could instead have done something like:

   $colour ||= "black";

Which would have defaulted C<< $colour >> to "black" if it were the empty
string.

=head1 ENVIRONMENT

=over

=item C<PERL_TYPE_PARAMS_XS>

Affects the building of accessors for C<compile_named_oo>. If set to true,
will use L<Class::XSAccessor>. If set to false, will use pure Perl. If this
environment variable does not exist, will use L<Class::XSAccessor> if it
is available.

=back


=head1 COMPARISONS WITH OTHER MODULES

=head2 Params::Validate

L<Type::Params> is not really a drop-in replacement for L<Params::Validate>;
the API differs far too much to claim that. Yet it performs a similar task,
so it makes sense to compare them.

=over

=item *

Type::Params will tend to be faster if you've got a sub which is called
repeatedly, but may be a little slower than Params::Validate for subs that
are only called a few times. This is because it does a bunch of work the
first time your sub is called to make subsequent calls a lot faster.

=item *

Params::Validate doesn't appear to have a particularly natural way of
validating a mix of positional and named parameters.

=item *

Type::Utils allows you to coerce parameters. For example, if you expect
a L<Path::Tiny> object, you could coerce it from a string.

=item *

If you are primarily writing object-oriented code, using Moose or similar,
and you are using Type::Tiny type constraints for your attributes, then
using Type::Params allows you to use the same constraints for method calls.

=item *

Type::Params comes bundled with Types::Standard, which provides a much
richer vocabulary of types than the type validation constants that come
with Params::Validate. For example, Types::Standard provides constraints
like C<< ArrayRef[Int] >> (an arrayref of integers), while the closest from
Params::Validate is C<< ARRAYREF >>, which you'd need to supplement with
additional callbacks if you wanted to check that the arrayref contained
integers.

Whatsmore, Type::Params doesn't just work with Types::Standard, but also
any other Type::Tiny type constraints.

=back

=head1 Params::ValidationCompiler

L<Params::ValidationCompiler> does basically the same thing as
L<Type::Params>.

=over

=item *

Params::ValidationCompiler and Type::Params are likely to perform fairly
similarly. In most cases, recent versions of Type::Params seem to be
I<slightly> faster, but except in very trivial cases, you're unlikely to
notice the speed difference. Speed probably shouldn't be a factor when
choosing between them.

=item *

Type::Params's syntax is more compact:

   state $check = compile(Object, Optional[Int], slurpy ArrayRef);

Versus:

   state $check = validation_for(
      params => [
         { type => Object },
         { type => Int,      optional => 1 },
         { type => ArrayRef, slurpy => 1 },
      ],
   );

=item *

L<Params::ValidationCompiler> probably has slightly better exceptions.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny>, L<Type::Coercion>, L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

