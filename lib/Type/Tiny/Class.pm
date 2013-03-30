package Type::Tiny::Class;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::VERSION   = '0.001';
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
	return $proto->class->new(@_) if blessed $proto; # DWIM
	
	my %opts = @_;
	_confess "need to supply class name" unless exists $opts{class};
	return $proto->SUPER::new(%opts);
}

sub class       { $_[0]{class} }
sub inlined     { $_[0]{inlined} ||= $_[0]->_build_inlined }

sub has_inlined { !!1 }

sub _build_constraint
{
	my $self  = shift;
	my $class = $self->class;
	return sub { blessed($_) and $_->isa($class) };
}

sub _build_inlined
{
	my $self  = shift;
	my $class = $self->class;
	my $var   = $_[0];
	return qq{blessed($var) and $var->isa(q[$class])};
}

sub _build_message
{
	my $self = shift;
	my $c = $self->class;
	return sub { sprintf 'value "%s" did not pass type constraint (not isa %s)', $_[0], $c } if $self->is_anon;
	my $name = "$self";
	return sub { sprintf 'value "%s" did not pass type constraint "%s" (not isa %s)', $_[0], $name, $c };
}

1;
