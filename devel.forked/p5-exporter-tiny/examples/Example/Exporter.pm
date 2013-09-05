use 5.006001;
use strict;
use warnings;

package Example::Exporter;

# Inherit from Exporter::Tiny.
#
use base 'Exporter::Tiny';

# The list of functions to export by default.
# Be conservative.
#
our @EXPORT = qw( fib );

# The list of functions which are allowed to
# be exported. Be liberal.
#
our @EXPORT_OK = qw( embiggen );

# Note that there was no need to list "fib"
# in @EXPORT_OK. It was in @EXPORT, so it's
# implicitly ok.

# This is the definition of the "fib" function
# that we want to export.
#
sub fib {
	my $n = $_[0];
	
	(int($n) eq $n) && ($n >= 0)
		or die "Expected natural number as argument; got '$n'";
	
	return $n if $n < 2;
	
	fib($n - 1) + fib($n - 2);
}

# We won't define a standard embiggen function.
# Instead we will generate one when requested.
#
sub _generate_embiggen {
	my ($class, $name, $arg, $globals) = @_;
	
	my $embiggen_amount = exists($arg->{amount}) ? $arg->{amount} : 1;
	
	# This is the sub that will be installed into
	# the caller's namespace.
	#
	return sub ($) {
		my $n = $_[0];
		return $n + $embiggen_amount;
	}
}

1; # Make Perl Happy™
