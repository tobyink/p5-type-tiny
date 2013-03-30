package Type::Tiny::Duck;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::Duck::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::Duck::VERSION   = '0.001';
}

use Scalar::Util qw< blessed >;

sub _confess ($;@)
{
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::confess;
}

use base "Type::Tiny";

sub new {
	my $proto = shift;
	my %opts = @_;
	_confess "need to supply list of methods" unless exists $opts{methods};
	$opts{methods} = [$opts{methods}] unless ref $opts{methods};
	return $proto->SUPER::new(%opts);
}

sub methods     { $_[0]{methods} }
sub inlined     { $_[0]{inlined} ||= $_[0]->_build_inlined }

sub has_inlined { !!1 }

sub _build_constraint
{
	my $self    = shift;
	my @methods = @{$self->methods};
	return sub { blessed($_[0]) and not grep(!$_[0]->can($_), @methods) };
}

sub _build_inlined
{
	my $self = shift;
	my $var  = $_[0];
	my @methods = @{$self->methods};
	local $" = q{ };
	return qq{ blessed($var) and not grep(!$var->can(\$_), qw/@methods/) };
}

sub _build_message
{
	my $self = shift;
	return sub { sprintf 'value "%s" did not pass type constraint', $_[0] } if $self->is_anon;
	my $name = "$self";
	return sub { sprintf 'value "%s" did not pass type constraint "%s"', $_[0], $name };
}

1;
