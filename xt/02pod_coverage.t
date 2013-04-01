use XT::Util;
use Test::More;
use Test::Pod::Coverage;

plan skip_all => __CONFIG__->{skip_all}
	if __CONFIG__->{skip_all};

my $p = { coverage_class => 'Pod::Coverage::CountParents' };

if ( __CONFIG__->{modules} )
{
	my @modules = @{ __CONFIG__->{modules} };
	pod_coverage_ok($_, $p, "$_ is covered") for @modules;
	done_testing(scalar @modules);
}
else
{
	all_pod_coverage_ok($p);
}

