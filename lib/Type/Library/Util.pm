package Type::Library::Util;

use 5.008001;
use strict;
use warnings;

sub _confess ($;@) {
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::confess;
}

use Scalar::Util qw< blessed >;
use Type::Library;
use Type::Tiny;

use Exporter qw< import >;
our @EXPORT = qw< declare as where message extends >;

sub as ($;@)
{
	parent => @_;
}

sub where (&)
{
	constraint => $_[0];
}

sub message (&)
{
	message => $_[0];
}

sub declare
{
	my $caller = caller->meta;
	my %opts;
	if (@_ % 2 == 0)
	{
		%opts = @_;
	}
	else
	{
		(my($name), %opts) = @_;
		_confess "cannot provide two names for type" if exists $opts{name};
		$opts{name} = $name;
	}
	
	if (defined $opts{parent} and not blessed $opts{parent})
	{
		$opts{parent} = $caller->get_type($opts{parent})
			or _confess "could not find parent type";
	}
	
	my $type = "Type::Tiny"->new(%opts);
	$caller->add_type($type) unless $type->is_anon;
	return $type;
}

sub extends
{
	my $caller = caller->meta;
	my @libs;
	
	foreach my $lib (@libs)
	{
		eval "require $lib" or _confess "could not load library '$lib': $@";
		$caller->add_type($lib->get_type($_)) for $lib->meta->type_names;
	}
}

1;
