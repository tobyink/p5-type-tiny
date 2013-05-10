use 5.008001;
use strict;
use warnings;

{
	package Type::Exception;

	BEGIN {
		$Type::Exception::AUTHORITY = 'cpan:TOBYINK';
		$Type::Exception::VERSION   = '0.005_02';
	}

	use overload
		q[""]    => sub { $_[0]->to_string },
		fallback => 1,
	;

	our %CarpInternal;
	$CarpInternal{$_}++ for qw(
		Eval::TypeTiny
		Exporter::TypeTiny
		Test::TypeTiny
		Type::Coercion
		Type::Coercion::Union
		Type::Exception
		Type::Library
		Type::Params
		Type::Registry
		Types::Standard
		Types::Standard::DeepCoercion
		Types::TypeTiny
		Type::Tiny
		Type::Tiny::Class
		Type::Tiny::Duck
		Type::Tiny::Enum
		Type::Tiny::Intersection
		Type::Tiny::Role
		Type::Tiny::Union
		Type::Utils
	);

	sub new
	{
		my $class = shift;
		my %params = (@_==1) ? %{$_[0]} : @_;
		return bless \%params, $class;
	}

	sub throw
	{
		my $class = shift;
		my ($level, %ctxt) = 0;
		while (defined scalar caller($level) and $CarpInternal{scalar caller($level)})
			{ $level++ };
		@ctxt{qw/ package file line /} = caller($level);
		die( $class->new(context => \%ctxt, @_) );
	}

	sub message    { $_[0]{message} ||= $_[0]->_build_message };
	sub context    { $_[0]{context} };

	sub to_string
	{
		my $e = shift;
		my $c = $e->context;
		
		$c
			? sprintf('%s at %s line %d.', $e->message, $c->{file}, $c->{line})
			: $e->message
	}
	
	sub _build_message
	{
		return 'An exception has occurred';
	}
}

{
	package Type::Exception::Assertion;

	BEGIN {
		$Type::Exception::Assertion::AUTHORITY = 'cpan:TOBYINK';
		$Type::Exception::Assertion::VERSION   = '0.005_02';
		our @ISA = qw(Type::Exception);
	}

	sub type       { $_[0]{type} };
	sub value      { $_[0]{value} };
	sub varname    { $_[0]{varname} ||= '$_' };

	sub has_type   { defined $_[0]{type} }; # sic

	sub message
	{
		my $e = shift;
		$e->varname eq '$_'
			? $e->SUPER::message
			: sprintf('%s (in %s)', $e->SUPER::message, $e->varname);
	}
	
	sub _build_message
	{
		my $e = shift;
		$e->has_type
			? sprintf('%s did not pass type constraint %s', Type::Tiny::_dd($e->value), $e->type)
			: sprintf('%s did not pass type constraint', Type::Tiny::_dd($e->value))
	}
	
	sub explain
	{
		my $e = shift;
		return [] unless $e->has_type;
		$e->_explain($e->type);
	}

	sub _explain
	{
		my $e = shift;
		my ($type, $value, $varname) = @_;
		$value   = $e->value                    if @_ < 2;
		$varname = ref($e) ? $e->varname : '$_' if @_ < 3;
		
		return unless ref $type;
		return if $type->check($value);
		
		if ($type->has_parent)
		{
			my $parent = $e->_explain($type->parent, $value, $varname);
			return [
				sprintf('%s is a subtype of %s', $type, $type->parent),
				@$parent,
			] if $parent;
		}
		
		if ($type->is_parameterized and $type->parent->has_deep_explanation)
		{
			my $deep = $type->parent->deep_explanation->($type, $value, $varname);
			return [
				sprintf('%s fails type constraint %s', $e->_displayvar($value, $varname), $type),
				@$deep,
			] if $deep;
		}
		
		return [
			sprintf('%s fails type constraint %s', $e->_displayvar($value, $varname), $type),
			sprintf('%s is defined as: %s', $type, $e->_codefor($type)),
		];
	}

	sub _displayvar
	{
		require Type::Tiny;
		shift;
		my ($value, $varname) = @_;
		return Type::Tiny::_dd($value) if $varname eq q{$_};
		return sprintf('%s (in %s)', Type::Tiny::_dd($value), $varname);
	}

	my $b;
	sub _codefor
	{
		shift;
		my $type = $_[0];
		
		return $type->inline_check('$_')
			if $type->can_be_inlined;
		
		$b ||= do {
			require B::Deparse;
			my $tmp = "B::Deparse"->new;
			$tmp->ambient_pragmas(strict => "all", warnings => "all");
			$tmp;
		};
		
		my $code = $b->coderef2text($type->constraint);
		$code =~ s/\s+/ /g;
		return "sub $code";
	}
}

{
	package Type::Exception::WrongNumberOfParameters;

	BEGIN {
		$Type::Exception::WrongNumberOfParameters::AUTHORITY = 'cpan:TOBYINK';
		$Type::Exception::WrongNumberOfParameters::VERSION   = '0.005_02';
		our @ISA = qw(Type::Exception);
	}

	sub minimum    { $_[0]{minimum} ||= 0 };
	sub maximum    { $_[0]{maximum} };
	sub got        { $_[0]{got} };

	sub has_minimum { 1 };
	sub has_maximum { exists $_[0]{maximum} };
	
	sub _build_message
	{
		my $e = shift;
		if ($e->has_minimum and $e->has_maximum and $e->minimum == $e->maximum)
		{
			return sprintf(
				"Wrong number of parameters; got %d; expected %d",
				$e->got,
				$e->minimum,
			);
		}
		elsif ($e->has_minimum and $e->has_maximum and $e->minimum < $e->maximum)
		{
			return sprintf(
				"Wrong number of parameters; got %d; expected %d to %d",
				$e->got,
				$e->minimum,
				$e->maximum,
			);
		}
		elsif ($e->has_minimum)
		{
			return sprintf(
				"Wrong number of parameters; got %d; expected at least %d",
				$e->got,
				$e->minimum,
			);
		}
		else
		{
			return sprintf(
				"Wrong number of parameters; got %d; expected the impossible",
				$e->got,
			);
		}
	}
}

1;
