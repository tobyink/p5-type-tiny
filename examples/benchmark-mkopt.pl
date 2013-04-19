use Benchmark qw(:all);
use Data::OptList ();
use Exporter::TypeTiny ();
use Test::More;

our @input = ("a".."i", [], "j".."k");

is_deeply(
	Data::OptList::mkopt(\@::input),
	Exporter::TypeTiny::mkopt(\@::input),
	'output identical',
);

open my $out, '>', \(my $cmp);
my $old = select $out;
cmpthese(-3, {
	Data_OptList      => q{ Data::OptList::mkopt(\@::input) },
	Exporter_TypeTiny => q{ Exporter::TypeTiny::mkopt(\@::input) },
});
select $old;

diag $cmp;

done_testing;
