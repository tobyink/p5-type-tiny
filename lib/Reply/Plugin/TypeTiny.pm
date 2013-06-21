package Reply::Plugin::TypeTiny;

use strict;
use warnings;

BEGIN {
  $Reply::Plugin::TypeTiny::AUTHORITY = 'cpan:TOBYINK';
  $Reply::Plugin::TypeTiny::VERSION   = '0.009_01';
}

use base 'Reply::Plugin';

use Scalar::Util qw(blessed);
use Term::ANSIColor;

sub mangle_error {
	my $self  = shift;
	my ($err) = @_;
	
	if (blessed $err and $err->isa("Type::Exception::Assertion"))
	{
		my $explain = $err->explain;
		if ($explain)
		{
			print color("cyan");
			print "Type::Exception::Assertion explain:\n";
			$self->_explanation($explain, "");
			local $| = 1;
			print "\n";
			print color("reset");
		}
	}
	
	return @_;
}

sub _explanation
{
	my $self = shift;
	my ($ex, $indent)  = @_;
	
	for my $line (@$ex)
	{
		if (ref($line) eq q(ARRAY))
		{
			print "$indent * Explain:\n";
			$self->_explanation($line, "$indent   ");
		}
		else
		{
			print "$indent * $line\n";
		}
	}
}

1;