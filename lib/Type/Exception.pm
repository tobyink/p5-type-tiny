package Type::Exception;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Exception::AUTHORITY = 'cpan:TOBYINK';
	$Type::Exception::VERSION   = '0.005_02';
}

use overload
	q[""]    => sub { $_[0]->to_string },
	fallback => 1,
;

sub new
{
	my $class = shift;
	my %params = (@_==1) ? %{$_[0]} : @_;
	return bless \%params, $class;
}

sub throw
{
	my $class = shift;
	die( $class->new(@_) );
}

sub message    { $_[0]{message} };
sub to_string  { shift->message };

package Type::Exception::Assertion;

BEGIN {
	$Type::Exception::Assertion::AUTHORITY = 'cpan:TOBYINK';
	$Type::Exception::Assertion::VERSION   = '0.005_02';
	our @ISA = qw(Type::Exception);
}

sub type       { $_[0]{type} };
sub value      { $_[0]{value} };

sub has_type   { defined $_[0]{type} }; # sic

sub explain
{
	my $e = shift;
	return [] unless $e->has_type;
	$e->_explain($e->type);
}

sub _explain
{
	my $e = shift;
	my ($type, $value) = @_;
	$value = $e->value if @_ < 2;
	
	return if $type->check($value);
	
	if ($type->has_parent)
	{
		my $parent = $e->_explain($type->parent);
		return [
			sprintf('%s is a subtype of %s', $type, $type->parent),
			@$parent,
		] if $parent;
	}
	
	return [
		sprintf('%s fails type constraint %s', Type::Tiny::_dd($value), $type),
		sprintf('%s is defined as: %s', $type, $e->_codefor($type)),
	];
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

1;
