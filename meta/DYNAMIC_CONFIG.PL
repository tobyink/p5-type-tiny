$meta->{prereqs}{runtime}{requires}{'Scalar::Util'}   = '1.13'  if $] < 5.007003;
$meta->{prereqs}{runtime}{requires}{'Data::Dumper'}   = '1.121' if $] < 5.008001;
$meta->{prereqs}{runtime}{requires}{'Text::Balanced'} = '1.95'  if $] < 5.007003;
$meta->{prereqs}{runtime}{requires}{'Exporter'}       = '5.57'  if $] < 5.009001;

if ($ENV{EXTENDED_TESTING} and $meta->{version} =~ /_/) {
	$meta->{prereqs}{test}{requires}{'Moose'} = '2.0600';
}

if ($ENV{AUTOMATED_TESTING} and "$^V" =~ /c$/) {
	print "cperl unsupported\n";
	exit(0);
}
