use strict;
use warnings;

BEGIN {
	package Types::Datetime;
	
	use Type::Library
		-base,
		-declare => qw( Datetime DatetimeHash EpochHash );
	use Type::Utils;
	use Types::Standard -types;
	
	class_type Datetime, { class => "DateTime" };
	
	declare DatetimeHash,
		as Dict[
			year       => Int,
			month      => Optional[ Int ],
			day        => Optional[ Int ],
			hour       => Optional[ Int ],
			minute     => Optional[ Int ],
			second     => Optional[ Int ],
			nanosecond => Optional[ Int ],
			time_zone  => Optional[ Str ],
		];
	
	declare EpochHash,
		as Dict[ epoch => Int ];
	
	coerce Datetime,
		from Int,          via { "DateTime"->from_epoch(epoch => $_) },
		from Undef,        via { "DateTime"->now },
		from DatetimeHash, via { "DateTime"->new(%$_) },
		from EpochHash,    via { "DateTime"->from_epoch(%$_) };
	
	1;
};

no thanks "Types::Datetime";
use DateTime ();
use Types::Datetime -all;
use Data::Dumper;

my $dt = to_Datetime { epoch => 328646500 };
$dt->set_time_zone("Asia/Tokyo");
print "$dt\n";
