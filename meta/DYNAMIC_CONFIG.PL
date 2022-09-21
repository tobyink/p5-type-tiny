	use strict;
	use warnings;
	no warnings 'uninitialized';
	
	# Old versions of Perl come with old versions of Exporter.
	# Not that we use Exporter a whole lot anyway.
	if ( $] lt 5.009001 ) {
		$meta->{prereqs}{runtime}{requires}{'Exporter'} = '5.57';
	}
	
	my $extended_testing = 0;
	if ( $ENV{EXTENDED_TESTING} and $] ge '5.008009' ) {
		++$extended_testing if $meta->{version} =~ /_/;
		++$extended_testing if $ENV{TRAVIS};
	}
	
	if ( $ENV{MINIMAL_INSTALL} ) {
		$extended_testing = 0;
		for my $stage ( qw( runtime test ) ) {
			delete $meta->{prereqs}{$stage}{recommends};
			delete $meta->{prereqs}{$stage}{suggests};
		}
	}
	
	if ( $extended_testing ) {
		$meta->{prereqs}{test}{requires}{'Moose'} = '2.0600';
		$meta->{prereqs}{test}{requires}{$_} = '0'
			for qw(
				bareword::filehandles
				Class::InsideOut
				Class::XSAccessor
				Devel::LexAlias
				Devel::Refcount
				indirect
				match::simple
				Moo
				MooseX::Getopt
				MooseX::Types::Common
				Mouse
				MouseX::Types::Common
				multidimensional
				Object::Accessor
				PadWalker
				Return::Type
				strictures
				Test::Fatal
				Test::LeakTrace
				Test::Requires
				Test::Tester
				Test::Warnings
			);
		if ( $] ge '5.028' ) {
			$meta->{prereqs}{test}{requires}{$_} = '0'
				for qw(
					Validation::Class::Simple
				);
		}
	}
	
	if ( $ENV{AUTOMATED_TESTING} and "$^V" =~ /c$/ ) {
		print "cperl unsupported by test suite (the vast majority of the distribution should still work)\n";
		exit(0);
	}
