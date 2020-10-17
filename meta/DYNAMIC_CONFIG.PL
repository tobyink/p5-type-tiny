$meta->{prereqs}{runtime}{requires}{'Scalar::Util'}   = '1.13'  if $] < 5.007003;
$meta->{prereqs}{runtime}{requires}{'Data::Dumper'}   = '1.121' if $] < 5.008001;
$meta->{prereqs}{runtime}{requires}{'Text::Balanced'} = '1.95'  if $] < 5.007003;
$meta->{prereqs}{runtime}{requires}{'Exporter'}       = '5.57'  if $] < 5.009001;

my $extened_testing = 0;
if ( $ENV{EXTENDED_TESTING} ) {
	$meta->{version} =~ /_/ and ++$extened_testing;
	$ENV{TRAVIS} and ++$extened_testing;
	$] ge '5.008008' and $extened_testing = 0;
}

if ( $extended_testing ) {
	$meta->{prereqs}{test}{requires}{'Moose'} = '2.0600';
	$meta->{prereqs}{test}{requires}{$_} = '0'
		for qw(
			Test::Requires
			Test::Fatal
			Test::LeakTrace
			Test::Tester
			Test::Warnings
			indirect
			multidimensional
			bareword::filehandles
			strictures
			Devel::Refcount
			Moo
			Mouse
			MooseX::Types::Common
			MouseX::Types::Common
			match::simple
			MooseX::Getopt
			Class::InsideOut
			Object::Accessor
			Type::Tie
			Return::Type
		);
	if ( $] ge '5.028' ) {
		$meta->{prereqs}{test}{requires}{$_} = '0'
			for qw(
				Validation::Class::Simple
				Class::XSAccessor
				PadWalker
				Devel::LexAlias
			);
	}
}

if ($ENV{AUTOMATED_TESTING} and "$^V" =~ /c$/) {
	print "cperl unsupported\n";
	exit(0);
}
