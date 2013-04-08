use strict;
use warnings;
use lib "lib", "../lib";

BEGIN {
	package Types::Datetime;
	
	use Type::Library
		-base,
		-declare => qw( Datetime DatetimeHash Duration EpochHash );
	use Type::Utils;
	use Types::Standard -types;
	
	require DateTime;
	require DateTime::Duration;
	
	class_type Datetime, { class => "DateTime" };
	
	class_type Duration, { class => "DateTime::Duration" };
	
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
		as Dict[
			epoch      => Int,
			time_zone  => Optional[ Str ],
		];
	
	coerce Datetime,
		from Int,          via { "DateTime"->from_epoch(epoch => $_) },
		from Undef,        via { "DateTime"->now },
		from DatetimeHash, via { "DateTime"->new(%$_) },
		from EpochHash,    via { "DateTime"->from_epoch(%$_) };
	
	$INC{"Types/Datetime.pm"} = __FILE__;
};

BEGIN {
	package Person;
	
	use Moose;
	use Types::Standard -moose, qw( Str Int Num );
	use Types::Datetime -moose, qw( Datetime Duration );
	
	has name => (
		is       => "ro",
		isa      => Str,
		required => 1,
	);
	
	has age => (
		is       => "ro",
		isa      => Int->plus_coercions(Num, 'int($_)', Duration, '$_->years'),
		coerce   => 1,
		init_arg => undef,
		lazy     => 1,
		builder  => "_build_age",
	);
	
	has date_of_birth => (
		is       => "ro",
		isa      => Datetime,
		coerce   => 1,
		required => 1,
	);
	
	sub _build_age
	{
		my $self = shift;
		return Datetime->class->now - $self->date_of_birth;
	}
};

my $me = Person->new(
	name          => "Toby Inkster",
	date_of_birth => { epoch => 328646500, time_zone => "Asia/Tokyo" },
);

printf("%s is %d years old.\n", $me->name, $me->age);
