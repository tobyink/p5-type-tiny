#!/usr/bin/env perl

use v5.014;

use Path::Tiny;
use Path::Iterator::Rule;
use Pod::POM;

use constant PROJ_NAME => 'Type-Tiny';
use constant PROJ_DIR  => path(path(__FILE__)->absolute->dirname)->parent;
use constant LIB_DIR   => PROJ_DIR->child('lib');
use constant TEST_DIR  => PROJ_DIR->child('t');

my $rule = Path::Iterator::Rule->new->file->name('*.t');

package Local::View
{
	use parent 'Pod::POM::View::Text';
	sub view_seq_link
	{
		my ($self, $link) = @_;
		$link =~ s/^.*?\|//;
		return $link;
	}
}

sub podpurpose
{
	my $pod = Pod::POM->new->parse_file($_[0]->openr_raw);
	my ($purpose) = grep $_->title eq 'PURPOSE', $pod->head1;
	my $content = $purpose->content->present('Local::View');
	my $trimmed = ($content =~ s/(\A\s+)|(\s+\z)//rms);
	$trimmed =~ s/\s+/ /g;
	
	$trimmed =~ s/"/\\"/g if $_[1];
	return $trimmed;
}

say '@prefix : <http://ontologi.es/doap-tests#>.';

MISC_TESTS:
{
	my $iter = $rule->clone->max_depth(1)->iter( TEST_DIR );

	while (my $file = $iter->())
	{		
		my $test = path($file);
		say "[] a :Test; :test_script f`${\ $test->relative(PROJ_DIR) } ${\ PROJ_NAME }`; :purpose \"${\ podpurpose($test,1) }\".";
	}
}

UNIT_TESTS:
{
	my $iter = $rule->iter( TEST_DIR->child('20-unit') );
	my %mods;

	while (my $file = $iter->())
	{		
		my $test = path($file);
		
		my ($module) = ($test =~ m(t/20-unit/([^/]+)/));
		$module =~ s{-}{::}g;
		
		push @{ $mods{$module} ||= [] }, $test;
	}
	
	for my $mod (sort keys %mods)
	{
		say "m`$mod ${\ PROJ_NAME }`";
		for my $test (sort @{ $mods{$mod} })
		{
			say "\t:unit_test [ a :UnitTest; :test_script f`${\ $test->relative(PROJ_DIR) } ${\ PROJ_NAME }`; :purpose \"${\ podpurpose($test,1) }\" ]";
		}
		say "\t.";
	}
}

INTEGRATION_TESTS:
{
	my $iter = $rule->iter( TEST_DIR->child('30-integration') );

	while (my $file = $iter->())
	{		
		my $test = path($file);
		say "[] a :IntegrationTest; :test_script f`${\ $test->relative(PROJ_DIR) } ${\ PROJ_NAME }`; :purpose \"${\ podpurpose($test,1) }\".";
	}
}

REGRESSION_TESTS:
{
	my $iter = $rule->iter( TEST_DIR->child('40-regression') );
	my %bugs;

	while (my $file = $iter->())
	{
		my $test = path($file);
		if ($test =~ m/rt([0-9]+)/)
		{
			push @{ $bugs{$1} ||= [] }, $test;
			next;
		}
		say "[] a :RegressionTest; :test_script f`${\ $test->relative(PROJ_DIR) } ${\ PROJ_NAME }`; :purpose \"${\ podpurpose($test,1) }\".";
	}
	
	for my $rt (sort { $a <=> $b } keys %bugs)
	{
		say "RT#$rt";
		for my $test (@{$bugs{$rt}})
		{
			say "\t:regression_test [ a :RegressionTest; :test_script f`${\ $test->relative(PROJ_DIR) } ${\ PROJ_NAME }`; :purpose \"${\ podpurpose($test,1) }\"];";
		}
		say "\t.";
	}
}

