package Type::Tiny::ConstrainedObject;

use 5.006001;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::ConstrainedObject::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::ConstrainedObject::VERSION   = '1.006000';
}

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

require Type::Tiny;
our @ISA = 'Type::Tiny';

my %errlabel = (
	parent     => 'a parent',
	constraint => 'a constraint coderef',
	inlined    => 'an inlining coderef',
);
sub new
{
	my $proto = shift;
	my %opts = (@_==1) ? %{$_[0]} : @_;
	for my $key (qw/ parent constraint inlined /) {
		next unless exists $opts{$key};
		_croak(
			'%s type constraints cannot have %s passed to the constructor',
			$proto->_short_name,
			$errlabel{$key},
		);
	}
	$proto->SUPER::new(%opts);
}

sub has_parent
{
	!!1;
}

sub parent
{
	require Types::Standard;
	Types::Standard::Object();
}

sub _short_name
{
	die "implement this";
}

1;

