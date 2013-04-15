use v5.10;
use strict;
use warnings;

BEGIN {
	package Types::XSD;
	
	no thanks;
	use B qw(perlstring);
	
	my %facets = (
		length => sub {
			my ($o, $var) = @_;
			return unless exists $o->{length};
			sprintf('length(%s)==%d', $var, delete $o->{length});
		},
		maxLength => sub {
			my ($o, $var) = @_;
			return unless exists $o->{maxLength};
			sprintf('length(%s)<=%d', $var, delete $o->{maxLength});
		},
		minLength => sub {
			my ($o, $var) = @_;
			return unless exists $o->{minLength};
			sprintf('length(%s)>=%d', $var, delete $o->{minLength});
		},
		pattern => sub {
			my ($o, $var) = @_;
			return unless exists $o->{pattern};
			my $p = delete $o->{pattern};
			$p =~ s/^"/"\^/;
			$p =~ s/"$/\$"/;
			sprintf('%s =~ m%ssm', $var, $p);
		},
		enumeration => sub {
			my ($o, $var) = @_;
			return unless exists $o->{enumeration};
			my $re = join "|", map quotemeta, @{$o->{enumeration}};
			sprintf('%s =~ m/^(?:%s)$/sm', $var, $re);
		},
		whiteSpace => sub {
			"!!1";
		},
		maxInclusive => sub {
			my ($o, $var) = @_;
			return unless exists $o->{maxInclusive};
			sprintf('%s <= %f', $var, delete $o->{maxInclusive});
		},
		minInclusive => sub {
			my ($o, $var) = @_;
			return unless exists $o->{minInclusive};
			sprintf('%s >= %f', $var, delete $o->{minInclusive});
		},
		maxExclusive => sub {
			my ($o, $var) = @_;
			return unless exists $o->{maxExclusive};
			sprintf('%s < %f', $var, delete $o->{maxExclusive});
		},
		minExclusive => sub {
			my ($o, $var) = @_;
			return unless exists $o->{minInclusive};
			sprintf('%s > %f', $var, delete $o->{minExclusive});
		},
		maxInclusiveStr => sub {
			my ($o, $var) = @_;
			return unless exists $o->{maxInclusive};
			sprintf('%s le %s', $var, perlstring delete $o->{maxInclusive});
		},
		minInclusiveStr => sub {
			my ($o, $var) = @_;
			return unless exists $o->{minInclusive};
			sprintf('%s ge %s', $var, perlstring delete $o->{minInclusive});
		},
		maxExclusiveStr => sub {
			my ($o, $var) = @_;
			return unless exists $o->{maxExclusive};
			sprintf('%s lt %s', $var, perlstring delete $o->{maxExclusive});
		},
		minExclusiveStr => sub {
			my ($o, $var) = @_;
			return unless exists $o->{minInclusive};
			sprintf('%s gt %s', $var, perlstring delete $o->{minExclusive});
		},
		totalDigits => sub {
			my ($o, $var) = @_;
			return unless exists $o->{totalDigits};
			sprintf('do { my $tmp = %s; ($tmp=~tr/0-9//) <= %d }', $var, delete $o->{totalDigits});
		},
		fractionDigits => sub {
			my ($o, $var) = @_;
			return unless exists $o->{fractionDigits};
			sprintf('do { my (undef, $tmp) = split /\\./, %s; ($tmp=~tr/0-9//) <= %d }', $var, delete $o->{fractionDigits});
		},
	);
	
	sub facet
	{
		my $self   = pop;
		my @facets = @_;
		
		return if $self->is_anon;
		&Scalar::Util::set_prototype(__PACKAGE__->can($self->name), ';@');
		
		my $inline_generator = sub
		{
			my %p = @_;
			# XXX - sanity check keys %p
			return sub {
				my $var = $_[1];
				sprintf(
					'(%s)',
					join(
						' and ',
						$self->inline_check($var),
						map($facets{$_}->(\%p, $var), @facets),
					),
				);
			};
		};
		
		$self->{inline_generator} = $inline_generator;
		$self->{constraint_generator} = sub {
			eval sprintf(
				'sub { %s }',
				$inline_generator->(@_)->($self, '$_[0]'),
			);
		};
	}

	use Types::Standard;
	use Type::Utils;
	use Type::Library -base, -declare => qw(
		AnyType AnySimpleType String NormalizedString Token Language Name
		NmToken NmTokens NcName Id IdRef IdRefs Entity Entities Boolean
		Base64Binary HexBinary Float Double AnyURI QName Notation Decimal
		Integer NonPositiveInteger NegativeInteger Long Int Short Byte
		NonNegativeInteger PositiveInteger UnsignedLong UnsignedInt
		UnsignedShort UnsignedByte Duration DateTime Time Date GYearMonth
		GYear GMonthDay GDay GMonth
	);
	
	declare AnyType, as Types::Standard::Any;
	
	declare AnySimpleType, as Types::Standard::Value;
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare String, as Types::Standard::Str;
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare NormalizedString, as Types::Standard::StrMatch[qr{^[^\t\r\n]*$}sm];

	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare Token, as intersection([
		NormalizedString,
		Types::Standard::StrMatch([qr{^\s}sm])->complementary_type,
		Types::Standard::StrMatch([qr{\s$}sm])->complementary_type,
		Types::Standard::StrMatch([qr{\s{2}}sm])->complementary_type,
	]);
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare Language, as Types::Standard::StrMatch[qr{^[a-zA-Z]{1,8}(?:-[a-zA-Z0-9]{1,8})*$}sm];
	
	# XXX - Name
	# XXX - NmToken
	# XXX - NmTokens
	# XXX - NcName
	# XXX - Id
	# XXX - IdRef
	# XXX - IdRefs
	# XXX - Entity
	# XXX - Entities

	facet qw( pattern whiteSpace ),
	declare Boolean, as Types::Standard::StrMatch[qr{^(?:true|false|0|1)$}ism];

	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare Base64Binary, as Types::Standard::StrMatch[qr{^[a-zA-Z0-9+\x{2f}=\s]+$}ism];

	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare HexBinary, as Types::Standard::StrMatch[qr{^[a-fA-F0-9]+$}ism];

	facet qw( pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive ),
	declare Float, as Types::Standard::Num;
	
	facet qw( pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive ),
	declare Double, as Types::Standard::Num;
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare AnyURI, as Types::Standard::Str,
	
	# XXX - QName
	# XXX - Notation
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare Decimal, as Types::Standard::StrMatch[qr{^[+-]?[0-9]+(?:\.[0-9]+)?$}ism];

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare Integer, as Types::Standard::Int;

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare NonPositiveInteger, as Integer,
		where     {  $_ <= 0  },
		inline_as { sprintf "(%s and $_ <= 0)", $_[0]->parent->inline_check($_) };

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare NegativeInteger, as NonPositiveInteger,
		where     {  $_ != 0  },
		inline_as { sprintf "(%s and $_ != 0)", $_[0]->parent->inline_check($_) };

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare NonNegativeInteger, as Integer,
		where     {  $_ >= 0  },
		inline_as { sprintf "(%s and $_ >= 0)", $_[0]->parent->inline_check($_) };

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare PositiveInteger, as NonNegativeInteger,
		where     {  $_ != 0  },
		inline_as { sprintf "(%s and $_ != 0)", $_[0]->parent->inline_check($_) };

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare Long, as Integer,
		where     {  $_ <= 9223372036854775807 and $_ >= -9223372036854775808  },
		inline_as { sprintf "(%s and $_ <= 9223372036854775807 and $_ >= -9223372036854775808)", $_[0]->parent->inline_check($_) };

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare Int, as Long,
		where     {  $_ <= 2147483647 and $_ >= -2147483648  },
		inline_as { sprintf "(%s and $_ <= 2147483647 and $_ >= -2147483648)", $_[0]->parent->inline_check($_) };

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare Short, as Int,
		where     {  $_ <= 32767 and $_ >= -32768  },
		inline_as { sprintf "(%s and $_ <= 32767 and $_ >= -32768)", $_[0]->parent->inline_check($_) };

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare Byte, as Short,
		where     {  $_ <= 127 and $_ >= -128  },
		inline_as { sprintf "(%s and $_ <= 127 and $_ >= -128)", $_[0]->parent->inline_check($_) };

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare UnsignedLong, as NonNegativeInteger,
		where     {  $_ <= 18446744073709551615 },
		inline_as { sprintf "(%s and $_ <= 18446744073709551615)", $_[0]->parent->inline_check($_) };

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare UnsignedInt, as UnsignedLong,
		where     {  $_ <= 4294967295 },
		inline_as { sprintf "(%s and $_ <= 4294967295)", $_[0]->parent->inline_check($_) };

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare UnsignedShort, as UnsignedInt,
		where     {  $_ <= 65535 },
		inline_as { sprintf "(%s and $_ <= 65535)", $_[0]->parent->inline_check($_) };

	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare UnsignedByte, as UnsignedShort,
		where     {  $_ <= 255 },
		inline_as { sprintf "(%s and $_ <= 255)", $_[0]->parent->inline_check($_) };

	# XXX - Duration
	# XXX - DateTime
	# XXX - Time
	# XXX - Date
	# XXX - GYearMonth
	# XXX - GYear
	# XXX - GMonthDay
	# XXX - GDay
	# XXX - GMonth
};

use Types::XSD qw(Token);

my $type = Token[maxLength => 8, minLength => 2];
say $type->inline_check('$XXX');
