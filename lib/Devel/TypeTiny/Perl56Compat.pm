#### B doesn't provide perlstring() in 5.6. Monkey patch it.

use B ();

*B::perlstring = sub {
	sprintf('"%s"', quotemeta($_[0]))
} unless exists &B::perlstring;

push @B::EXPORT_OK, 'perlstring';

1;
