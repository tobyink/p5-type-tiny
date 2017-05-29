use strict;
use warnings;

# Type constraint library…
BEGIN {
	package Types::Bookish;
	$INC{'Types/Bookish.pm'} = __FILE__;
	
	use Type::Library -base,
		-declare => qw( PageNumber PageRangeArray PageRange PageSeriesArray PageSeries );
	use Types::Standard qw( Str StrMatch Tuple ArrayRef );
	use Types::Common::Numeric qw( PositiveInt );
	use Type::Utils -all;
	
	declare PageNumber,
		as PositiveInt,
	;
	
	declare PageRangeArray,
		as Tuple[ PageNumber, PageNumber ],
		constraint => '$_->[0] < $_->[1]',
	;
	
	declare PageRange,
		as StrMatch[ qr/\A([0-9]+)-([0-9]+)\z/, PageRangeArray ],
	;
	
	coerce PageRangeArray
		from PageRange, q{ [ split /-/, $_ ] },
	;
	
	coerce PageRange
		from PageRangeArray, q{ join q/-/, @$_ },
	;

	declare PageSeriesArray,
		as ArrayRef[ PageNumber | PageRange ],
		constraint => (
			# This constraint prevents page series arrays from being in
			# the wrong order, like [ 20, '4-16', 12 ].
			'my $J = join q/-/, @$_; '.
			'my $S = join q/-/, sort { $a <=> $b } split /-/, $J; '.
			'$S eq $J'
		),
	;

	declare PageSeries,
		as Str,
		constraint => (
			'my $tmp = [split /\s*,\s*/]; '.
			PageSeriesArray->inline_check('$tmp')
		),
	;
	
	coerce PageSeriesArray
		from PageSeries,  q{ [ split /\s*,\s*/, $_ ] },
		from PageRange,   q{ [ $_ ] },
		from PageNumber,  q{ [ $_ ] },
	;
	
	coerce PageSeries
		from PageSeriesArray, q{ join q[,], @$_ },
	;

	
	__PACKAGE__->meta->make_immutable;
}

use Types::Bookish -types;
use Perl::Tidy;

PageNumber->assert_valid('4');

PageRangeArray->assert_valid([4, 16]);

PageRange->assert_valid('4-16');

PageSeriesArray->assert_valid([ '4-16', 18, 20 ]);

PageSeries->assert_valid('4-16, 18, 20');

Perl::Tidy::perltidy(
	source      => \( PageSeries->inline_check('$DATA') ),
	destination => \( my $tidied ),
);

print $tidied;
