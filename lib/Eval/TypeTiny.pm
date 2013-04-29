package Eval::TypeTiny;

use strict;
use warnings;

sub _clean_eval
{
	no warnings;
	local $@;
	local $SIG{__DIE__};
	my $r = eval $_[0];
	my $e = $@;
	return ($r, $e);
}

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003_09';
our @EXPORT    = qw( eval_closure );

sub _croak ($;@)
{
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::croak;
}

sub import
{
	# do the shuffle!
	no warnings "redefine";
	our @ISA = qw( Exporter::TypeTiny );
	require Exporter::TypeTiny;
	my $next = \&Exporter::TypeTiny::import;
	*import = $next;
	goto $next;
}

my $sandbox = 0;
sub eval_closure
{
	$sandbox++;
	
	my (%args) = @_;
	$args{line}   = 1 unless defined $args{line};
	$args{source} = qq{#line $args{line} "$args{description}"\n} . $args{source}
		if defined $args{description} && !($^P & 0x10);
	$args{environment} ||= {};
	
	for my $k (sort keys %{$args{environment}})
	{
		next if $k =~ /^\$/ && ref($args{environment}{$k}) =~ /^(SCALAR|REF)$/;
		next if $k =~ /^\@/ && ref($args{environment}{$k}) eq q(ARRAY);
		next if $k =~ /^\%/ && ref($args{environment}{$k}) eq q(HASH);
		_croak "Expected a variable name and ref; got $k => $args{environment}{$k}";
	}
	
	my @keys      = sort keys %{$args{environment}};
	my $i         = 0;
	my $source    = join "\n" => (
		"package Eval::TypeTiny::Sandbox$sandbox;",
		"sub {",
		map(sprintf('my %s = %s{$_[%d]};', $_, substr($_, 0, 1), $i++), @keys),
		"return $args{source}",
		"}",
	);
	
	my ($compiler, $e) = _clean_eval($source);
	_croak "Failed to compile source because: $e\n\nSOURCE: $source" if $e;
	
	return $compiler->(@{$args{environment}}{@keys});
}

1;
