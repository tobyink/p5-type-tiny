use v5.10;
use strict;
use warnings;

BEGIN {
	package Types::XSD;
	
	no thanks;
	use B qw(perlstring);
	use Carp;
	
	use DateTimeX::Auto qw( dt dur );
	use XML::RegExp;
	
	sub create_range_check
	{
		my $class = $_[0]; eval "require $class";
		my ($lower, $upper) = map(defined($_) ? $class->new($_) : $_, @_[1,2]);
		my ($lexcl, $uexcl) = map(!!$_, @_[3,4]);
		
		my $checker =
			(defined $lower and defined $upper and $lexcl and $uexcl)
				? sub { my $n = $class->new($_); $n > $lower and $n < $upper } :
			(defined $lower and defined $upper and $lexcl)
				? sub { my $n = $class->new($_); $n > $lower and $n <= $upper } :
			(defined $lower and defined $upper and $uexcl)
				? sub { my $n = $class->new($_); $n >= $lower and $n < $upper } :
			(defined $lower and defined $upper)
				? sub { my $n = $class->new($_); $n >= $lower and $n <= $upper } :
			(defined $lower and $lexcl)
				? sub { $class->new($_) > $lower } :
			(defined $upper and $uexcl)
				? sub { $class->new($_) < $upper } :
			(defined $lower)
				? sub { $class->new($_) >= $lower } :
			(defined $upper)
				? sub { $class->new($_) <= $upper } :
			sub { !!1 };
		
		my $inlined = sub {
			my $var = $_[1];
			my @checks;
			push @checks, sprintf('$n >%s "%s"->new("%s")', $lexcl?'':'=', $class, $lower) if defined $lower;
			push @checks, sprintf('$n <%s "%s"->new("%s")', $uexcl?'':'=', $class, $upper) if defined $upper;
			my $code = sprintf(
				'%s and do { my $n = "%s"->new(%s); %s }',
				Types::Standard::Int()->inline_check($var),
				$class,
				$var,
				join(" and ", @checks),
			);
		};
		
		return (
			constraint  => $checker,
			inlined     => $inlined,
		);
	}
	
	sub quick_range_check
	{
		my $class = $_[0]; eval "require $class";
		my ($lower, $upper) = map(defined($_) ? $class->new($_) : $_, @_[1,2]);
		my ($lexcl, $uexcl) = map(!!$_, @_[3,4]);
		my $var = $_[5];
		my @checks;
		push @checks, sprintf('$n >%s "%s"->new("%s")', $lexcl?'':'=', $class, $lower) if defined $lower;
		push @checks, sprintf('$n <%s "%s"->new("%s")', $uexcl?'':'=', $class, $upper) if defined $upper;
		my $code = sprintf(
			'do { my $n = "%s"->new(%s); %s }',
			$class,
			$var,
			join(" and ", @checks),
		);
	}
	
	use constant MAGIC_DATES => map dt($_), qw( 1696-09-01 1697-02-01 1903-03-01 1903-07-01 );
	use constant MAGIC_TABLE => +{ "-1-1-1-1" => -1, "0000" => 0, "1111" => 1 };
	sub dur_cmp
	{
		my @durations = map ref($_) ? $_ : dur($_), @_[0,1];
		my $result    = join q[], map "DateTime::Duration"->compare(@durations, $_), MAGIC_DATES;
		return MAGIC_TABLE->{$result} if exists MAGIC_TABLE->{$result};
		return undef;
	}
	
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
			my $re = join "|", map quotemeta, @{delete $o->{enumeration}};
			sprintf('%s =~ m/^(?:%s)$/sm', $var, $re);
		},
		whiteSpace => sub {
			my ($o, $var) = @_;
			return unless exists $o->{whiteSpace};
			delete($o->{whiteSpace});
			"!!1";
		},
		maxInclusive => sub {
			my ($o, $var) = @_;
			return unless exists $o->{maxInclusive};
			quick_range_check("Math::BigInt", undef, delete($o->{maxInclusive}), undef, undef, $var);
		},
		minInclusive => sub {
			my ($o, $var) = @_;
			return unless exists $o->{minInclusive};
			quick_range_check("Math::BigInt", delete($o->{minInclusive}), undef, undef, undef, $var);
		},
		maxExclusive => sub {
			my ($o, $var) = @_;
			return unless exists $o->{maxExclusive};
			quick_range_check("Math::BigInt", undef, delete($o->{maxExclusive}), undef, 1, $var);
		},
		minExclusive => sub {
			my ($o, $var) = @_;
			return unless exists $o->{minExclusive};
			quick_range_check("Math::BigInt", delete($o->{minExclusive}), undef, 1, undef, $var);
		},
		maxInclusiveFloat => sub {
			my ($o, $var) = @_;
			return unless exists $o->{maxInclusive};
			quick_range_check("Math::BigFloat", undef, delete($o->{maxInclusive}), undef, undef, $var);
		},
		minInclusiveFloat => sub {
			my ($o, $var) = @_;
			return unless exists $o->{minInclusive};
			quick_range_check("Math::BigFloat", delete($o->{minInclusive}), undef, undef, undef, $var);
		},
		maxExclusiveFloat => sub {
			my ($o, $var) = @_;
			return unless exists $o->{maxExclusive};
			quick_range_check("Math::BigFloat", undef, delete($o->{maxExclusive}), undef, 1, $var);
		},
		minExclusiveFloat => sub {
			my ($o, $var) = @_;
			return unless exists $o->{minExclusive};
			quick_range_check("Math::BigFloat", delete($o->{minExclusive}), undef, 1, undef, $var);
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
			return unless exists $o->{minExclusive};
			sprintf('%s gt %s', $var, perlstring delete $o->{minExclusive});
		},
		maxInclusiveDuration => sub {
			my ($o, $var) = @_;
			return unless exists $o->{maxInclusive};
			sprintf('(Types::XSD::dur_cmp(%s, %s)||0) <= 0', $var, perlstring delete $o->{maxInclusive});
		},
		minInclusiveDuration => sub {
			my ($o, $var) = @_;
			return unless exists $o->{minInclusive};
			sprintf('(Types::XSD::dur_cmp(%s, %s)||0) >= 0', $var, perlstring delete $o->{minInclusive});
		},
		maxExclusiveDuration => sub {
			my ($o, $var) = @_;
			return unless exists $o->{maxExclusive};
			sprintf('(Types::XSD::dur_cmp(%s, %s)||0) < 0', $var, perlstring delete $o->{maxExclusive});
		},
		minExclusiveDuration => sub {
			my ($o, $var) = @_;
			return unless exists $o->{minExclusive};
			sprintf('(Types::XSD::dur_cmp(%s, %s)||0) > 0', $var, perlstring delete $o->{minExclusive});
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
		
		return if $self->is_anon;
		
		no strict qw( refs );
		no warnings qw( redefine prototype );
		*{$self->name} = __PACKAGE__->_mksub($self);
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
	
	our @EXPORT_OK = qw( in_range );
	
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
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare Name, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::Name)$}sm];
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare NmToken, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::NmToken)$}sm];
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare NmTokens, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::NmToken)(?:\s+$XML::RegExp::NmToken)*$}sm];
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare NcName, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::NCName)$}sm];
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare Id, as NcName;
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare IdRef, as NcName;
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare IdRefs, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::NCName)(?:\s+$XML::RegExp::NCName)*$}sm];
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare Entity, as NcName;
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare Entities, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::NCName)(?:\s+$XML::RegExp::NCName)*$}sm];
	
	facet qw( pattern whiteSpace ),
	declare Boolean, as Types::Standard::StrMatch[qr{^(?:true|false|0|1)$}ism];
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare Base64Binary, as Types::Standard::StrMatch[qr{^[a-zA-Z0-9+\x{2f}=\s]+$}ism];
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare HexBinary, as Types::Standard::StrMatch[qr{^[a-fA-F0-9]+$}ism];
	
	facet qw( pattern enumeration whiteSpace maxInclusiveFloat maxExclusiveFloat minInclusiveFloat minExclusiveFloat ),
	declare Float, as Types::Standard::Num;
	
	facet qw( pattern enumeration whiteSpace maxInclusiveFloat maxExclusiveFloat minInclusiveFloat minExclusiveFloat ),
	declare Double, as Types::Standard::Num;
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare AnyURI, as Types::Standard::Str,
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare QName, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::QName)$}sm];
	
	facet qw( length minLength maxLength pattern enumeration whiteSpace ),
	declare Notation, as QName;
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusiveFloat maxExclusiveFloat minInclusiveFloat minExclusiveFloat ),
	declare Decimal, as Types::Standard::StrMatch[qr{^[+-]?[0-9]+(?:\.[0-9]+)?$}ism];
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare Integer, as Types::Standard::Int;
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare NonPositiveInteger, as Integer, create_range_check("Math::BigInt", undef, 0);
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare NegativeInteger, as NonPositiveInteger, create_range_check("Math::BigInt", undef, -1);
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare NonNegativeInteger, as Integer, create_range_check("Math::BigInt", 0, undef);
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare PositiveInteger, as NonNegativeInteger, create_range_check("Math::BigInt", 1, undef);
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare Long, as Integer, create_range_check("Math::BigInt", q[-9223372036854775808], q[9223372036854775807]);
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare Int, as Long, create_range_check("Math::BigInt", q[-2147483648], q[2147483647]);
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare Short, as Int, create_range_check("Math::BigInt", q[-32768], q[32767]);
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare Byte, as Short, create_range_check("Math::BigInt", q[-128], q[127]);
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare UnsignedLong, as NonNegativeInteger, create_range_check("Math::BigInt", q[0], q[18446744073709551615]);
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare UnsignedInt, as UnsignedLong, create_range_check("Math::BigInt", q[0], q[4294967295]);
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare UnsignedShort, as UnsignedInt, create_range_check("Math::BigInt", q[0], q[65535]);
	
	facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
	declare UnsignedByte, as UnsignedShort, create_range_check("Math::BigInt", q[0], q[255]);
	
	facet qw( pattern whiteSpace enumeration maxInclusiveDuration maxExclusiveDuration minInclusiveDuration minExclusiveDuration ),
	declare Duration, as Types::Standard::StrMatch[
		qr{^P
			(?:[0-9]+Y)?
			(?:[0-9]+M)?
			(?:[0-9]+D)?
			(?:T
				(?:[0-9]+H)?
				(?:[0-9]+M)?
				(?:[0-9]+(?:\.[0-9]+)?S)?
			)?
		$}xism
	];
	
	# XXX - DateTime
	# XXX - Time
	# XXX - Date
	# XXX - GYearMonth
	# XXX - GYear
	# XXX - GMonthDay
	# XXX - GDay
	# XXX - GMonth
};

use Types::XSD -types;

my $type = Types::XSD::Notation[enumeration => [qw[ foo bar baz ]]];
say $type->inline_check('$XXX');
