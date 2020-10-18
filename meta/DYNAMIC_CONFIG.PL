$meta->{prereqs}{runtime}{requires}{'Scalar::Util'}   = '1.13'  if $] < 5.007003;
$meta->{prereqs}{runtime}{requires}{'Data::Dumper'}   = '1.121' if $] < 5.008001;
$meta->{prereqs}{runtime}{requires}{'Text::Balanced'} = '1.95'  if $] < 5.007003;
$meta->{prereqs}{runtime}{requires}{'Exporter'}       = '5.57'  if $] < 5.009001;

my $extended_testing = 0;
if ( $ENV{EXTENDED_TESTING} and $] ge '5.008009' ) {
	++$extended_testing if $meta->{version};
	++$extended_testing if $ENV{TRAVIS};
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
			Type::Tie
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
