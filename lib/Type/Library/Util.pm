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
our @EXPORT = qw< declare as where message >;

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
	my ($name, %opts) = @_;
	$opts{name} = $name;
	
	if (defined $opts{parent} and not blessed $opts{parent})
	{
		$opts{parent} = $caller->get_type($opts{parent})
			or _confess "could not find parent type";
	}
	
	$caller->add_type(%opts);
}

1;
