#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use constant {
	ORIG => '../lib/Exporter/TypeTiny.pm',
	FORK => 'p5-exporter-tiny/lib/Exporter/Tiny.pm',
};

my %POD = (

'NAME'=><<POD,

Exporter::Tiny - an exporter with the features of Sub::Exporter but only core dependencies

POD

'SEE ALSO'=><<POD,

L<Exporter::TypeTiny>,
L<Sub::Exporter>,
L<Exporter>.

POD

'BUGS'=><<POD,

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Exporter-Tiny>.

POD
);

open(my $orig, '<', ORIG);
open(my $fork, '>', FORK);
while (<$orig>)
{
	s/Exporter::TypeTiny/Exporter::Tiny/g;
	s/EXPORTER::TYPETINY/EXPORTER::TINY/g;
	
	if (/\Asub _croak/)
	{
		$_ = q[sub _croak ($;@) { require Carp; my $fmt = shift; @_ = sprintf($fmt, @_); goto \&Carp::croak }]."\n";
	}
	
	elsif (/\A=head1 (.+)/ and exists($POD{$1}))
	{
		$_ .= $POD{$1};
		PODSLURP: while (defined(my $line = <$orig>))
		{
			if ($line =~ /\A=head1/) # come too far
			{
				seek($orig, -length($line), 1); # backtrack
				last PODSLURP; # done
			}
		}
	}
	
	print {$fork} $_;
}
close($orig);
close($fork);
