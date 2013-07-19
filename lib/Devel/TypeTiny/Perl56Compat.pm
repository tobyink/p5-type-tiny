#### B doesn't provide perlstring() in 5.6. Monkey patch it.

use B ();

sub B::perlstring
{
	sprintf('"%s"', quotemeta($_[0]))
}

push @B::EXPORT_OK, 'perlstring';

1;
