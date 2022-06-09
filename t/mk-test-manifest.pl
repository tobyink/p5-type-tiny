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
	my $content = eval { $purpose->content->present('Local::View') } || "(Unknown.)";
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
	my $iter = $rule->iter( TEST_DIR->child('20-modules') );
	my %mods;
	
	while (my $file = $iter->())
	{
		my $test = path($file);
		
		my ($module) = ($test =~ m(t/20-modules/([^/]+)/));
		$module =~ s{-}{::}g;
		
		push @{ $mods{$module} ||= [] }, $test;
	}
	
	for my $mod (sort keys %mods)
	{
		say "m`$mod ${\ PROJ_NAME }`";
		for my $test (sort @{ $mods{$mod} })
		{
			say "\t:test [ a :AutomatedTest; :test_script f`${\ $test->relative(PROJ_DIR) } ${\ PROJ_NAME }`; :purpose \"${\ podpurpose($test,1) }\" ];";
		}
		say "\t.";
	}
}

INTEGRATION_TESTS:
{
	my $iter = $rule->iter( TEST_DIR->child('30-external') );
	
	while (my $file = $iter->())
	{
		my $test = path($file);
		say "[] a :AutomatedTest; :test_script f`${\ $test->relative(PROJ_DIR) } ${\ PROJ_NAME }`; :purpose \"${\ podpurpose($test,1) }\".";
	}
}

REGRESSION_TESTS:
{
	my $iter = $rule->iter( TEST_DIR->child('40-bugs') );
	my %bugs;
	my %ghbugs;
	
	while (my $file = $iter->())
	{
		my $test = path($file);
		if ($test =~ m/\/rt([0-9]+)/)
		{
			push @{ $bugs{$1} ||= [] }, $test;
			next;
		}
		elsif ($test =~ m/\/gh([0-9]+)/) {
			push @{ $ghbugs{$1} ||= [] }, $test;
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

	for my $gh (sort { $a <=> $b } keys %ghbugs)
	{
		say "<tdb:2013:https://github.com/tobyink/p5-type-tiny/issues/$gh>";
		for my $test (@{$ghbugs{$gh}}) {
			say "\t:regression_test [ a :RegressionTest; :test_script f`${\ $test->relative(PROJ_DIR) } ${\ PROJ_NAME }`; :purpose \"${\ podpurpose($test,1) }\"];";
		}
		say "\t.";
	}
}

