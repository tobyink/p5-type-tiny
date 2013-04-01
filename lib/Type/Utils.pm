package Type::Utils;

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
our @EXPORT = qw< 
	declare as where message extends inline_as
	class role duck_type
>;

sub as ($;@)
{
	parent => @_;
}

sub class ($;@)
{
	bless => "Type::Tiny::Class", class => @_;
}

sub role ($;@)
{
	bless => "Type::Tiny::Role", role => @_;
}

sub duck_type ($;@)
{
	bless => "Type::Tiny::Duck", methods => @_;
}

sub where (&;@)
{
	constraint => @_;
}

sub inline_as (&;@)
{
	my $coderef = shift;
	inlined => sub { local $_ = $_[1]; $coderef->(@_) }, @_;
}

sub message (&;@)
{
	message => @_;
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
	
	$opts{library} = blessed($caller) || $caller;
	
	my $type;
	if (defined $opts{parent})
	{
		$type = delete($opts{parent})->create_child_type(%opts);
	}
	else
	{
		my $bless = delete($opts{bless}) || "Type::Tiny";
		eval "require $bless";
		$type = $bless->new(%opts);
	}
	
	$caller->add_type($type) unless $type->is_anon;
	return $type;
}

sub extends
{
	my $caller = caller->meta;
	
	foreach my $lib (@_)
	{
		eval "require $lib" or _confess "could not load library '$lib': $@";
		$caller->add_type($lib->get_type($_)) for $lib->meta->type_names;
	}
}

1;
