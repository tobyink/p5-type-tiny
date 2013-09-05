use XT::Util;
use Test::More tests => 1;
use Test::RDF::DOAP::Version;
doap_version_ok(__CONFIG__->{package}, __CONFIG__->{version_from});

