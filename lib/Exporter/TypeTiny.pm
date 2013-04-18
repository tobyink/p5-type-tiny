package Exporter::TypeTiny;

use 5.008001;
use strict;   no strict qw(refs);
use warnings; no warnings qw(void once uninitialized numeric redefine);

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003_03';

sub _croak ($;@) {
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::croak;
}

sub import
{
	my $class = shift;
	my @args  = @_ ? @_ : @{"$class\::EXPORT"};
	my $opts  = mkopt(\@args);
	
	my $global_opts = { into => scalar caller };
	my @want;
	
	while (@$opts)
	{
		my $opt = shift @{$opts};
		my ($name, $value) = @$opt;
		
		$name =~ /^[:-](.+)$/
			? push(@$opts, $class->_exporter_expand_tag($1, $value, $global_opts))
			: push(@want, $opt);
	}
	
	$class->_exporter_validate_opts($global_opts);
	
	for my $wanted (@want)
	{
		my %symbols = $class->_exporter_expand_sub(@$wanted, $global_opts);
		for my $name (keys %symbols)
		{
			$class->_exporter_install_sub($name, $wanted->[1], $global_opts, $symbols{$name});
		}
	}
}

sub _exporter_validate_opts
{
	1;
}

sub _exporter_expand_tag
{
	my $class = shift;
	my ($name, $value, $globals) = @_;
	my $tags  = \%{"$class\::EXPORT_TAGS"};
	
	if (exists $tags->{$name})
	{
		return map [$_ => $value], @{$tags->{$name}};
	}
	elsif ($name eq 'all')
	{
		return map [$_ => $value], @{"$class\::EXPORT"}, @{"$class\::EXPORT_OK"};
	}
	elsif ($name eq 'default')
	{
		return map [$_ => $value], @{"$class\::EXPORT"};
	}
	else
	{
		$globals->{$name} = $value || 1;
		return;
	}
}

sub _exporter_expand_sub
{
	my $class = shift;
	my ($name, $value, $globals) = @_;
	
	if (exists &{"$class\::$name"})
	{
		return ($name => \&{"$class\::$name"});
	}
	
	$class->_exporter_fail(@_);
}

sub _exporter_fail
{
	my $class = shift;
	my ($name, $value, $globals) = @_;
	_croak("Could not find sub '$name' to export in package '$class'");
}

sub _exporter_install_sub
{
	my $class = shift;
	my ($name, $value, $globals, $sym) = @_;
	
	$name = $value->{-as} || $name;
	
	if (ref($name) eq q(SCALAR))
	{
		$$name = $sym;
		return;
	}
	
	if (my $prefix = $value->{-prefix} || $globals->{prefix})
	{
		$name = "$prefix$name";
	}
	if (my $suffix = $value->{-suffix} || $globals->{suffix})
	{
		$name = "$name$suffix";
	}
	
	my $into = $globals->{into};	
	return ($into->{$name} = $sym) if ref($into) eq q(HASH);
	
	for (grep ref, $into->can($name))
	{
		require B;
		my $cv = B::svref_2object($_);
		$cv->STASH->NAME eq $into
			and _croak("Refusing to overwrite local sub '$name' with export from $class");
	}
	*{"$into\::$name"} = $sym;
}

sub mkopt
{
	my ($in) = @_;
	my @out;
	
	$in = [map(($_ => ref($in->{$_}) ? $in->{$_} : ()), sort keys %$in)]
		if ref($in) eq q(HASH);
	
	for (my $i = 0; $i < @$in; $i++)
	{
		my $k = $in->[$i];
		my $v;
		
		($i == $#$in)         ? ($v = undef) :
		!defined($in->[$i+1]) ? (++$i, ($v = undef)) :
		!ref($in->[$i+1])     ? ($v = undef) :
		($v = $in->[++$i]);
		
		push @out, [ $k => $v ];
	}
	
	return \@out;
}

1;

__END__

=encoding utf-8

=pod

Nothing to see here. Move along.

=cut
