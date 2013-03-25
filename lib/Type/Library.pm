package Type::Library;

use 5.008003;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::VERSION   = '0.001';
}

use Scalar::Util qw< blessed >;
use Type::Tiny;

sub _confess ($;@) {
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::confess;
}

sub import
{
	my $meta             = shift->meta;
	my ($opts, @exports) = $meta->_process_tags(@_);
	$opts->{caller}      = caller;
	$meta->_export($_, $opts) for @exports;
}

sub _process_tags
{
	my $meta = shift; # private; no need for ->meta
	my ($opts, @exports) = ({});
	
	for my $arg (@_)
	{
		if ($arg =~ /^[:-]moose$/i)
			{ $opts->{moose} = 1 }
		elsif ($arg =~ /^[:-]all$/i)
			{ push @exports, map { $_, "is_$_", "to_$_", "assert_$_" } $meta->type_names }
		elsif ($arg =~ /^[:-](assert|is|to)$/i)
			{ push @exports, map "$1\_$_", $meta->type_names }
		elsif ($arg =~ /^[:-]types$/i)
			{ push @exports, $meta->type_names }
		elsif ($arg =~ /^\+(.+)$/i)
			{ push @exports, map { $_, "is_$_", "to_$_", "assert_$_" } $1 }
		else
			{ push @exports, $arg }
	}
	
	return ($opts, @exports);
}

sub _export
{
	my $meta = shift; # private; no need for ->meta
	my ($subname, $opts) = @_;
	my $class = blessed($meta);
	
	no strict "refs";
	if ($subname =~ /^(is|to)_/ and my $coderef = $class->can($subname))
	{
		*{join("::", $opts->{caller}, $subname)} = $coderef;
		return;
	}
	
	if (my $type = $meta->get_type($subname))
	{
		*{join("::", $opts->{caller}, $subname)} =
			$opts->{moose} ? sub (;$) { $type->as_moose(@_) } : sub (;$) { @_ ? $type->with_params(@_) : $type };
		return;
	}
	
	_confess "'%s' is not exported by '%s'", $subname, $class;
}

sub meta
{
	no strict "refs";
	no warnings "once";
	return $_[0] if blessed $_[0];
	${"$_[0]\::META"} ||= bless {}, $_[0];
}

sub add_type
{
	my $meta = shift->meta;
	my $type = blessed($_[0]) ? $_[0] : ref($_[0]) ? "Type::Tiny"->new($_[0]) : "Type::Tiny"->new(@_);
	my $name = $type->name;
	
	$meta->{types} ||= {};
	_confess 'type %s already exists in this library', $name if exists $meta->{types}{$name};
	_confess 'cannot add anonymous type to a library' if $type->is_anon;
	$meta->{types}{$name} = $type;
	
	no strict "refs";
	my $class = blessed($meta);
	*{"$class\::$name"   }     = sub (;$) { $type };
	*{"$class\::is_$name"}     = sub { $type->check($_[0]) };
	*{"$class\::to_$name"}     = sub { $type->coerce($_[0]) };
	*{"$class\::assert_$name"} = sub { $type->assert_valid($_[0]) };
	return $type;
}

sub get_type
{
	my $meta = shift->meta;
	$meta->{types}{$_[0]};
}

sub has_type
{
	my $meta = shift->meta;
	exists $meta->{types}{$_[0]};
}

sub type_names
{
	my $meta = shift->meta;
	keys %{ $meta->{types} };
}

1;

