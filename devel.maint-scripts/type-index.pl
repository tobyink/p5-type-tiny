#!perl

use strict;
use warnings;

while (<DATA>) {
	chomp;
	my ($type, $library, $coercions, $parameterizable, $summary) = split /\t/;
	
	print "=item *\n\n";
	print "B<< $type >>";
	print " I<< [has coercion] >>" if $coercions =~ /y/i;
	print " I<< [parameterizable] >>" if $parameterizable =~ /y/i;
	print " in L<$library>\n\n";
	print $summary, "\n\n";
}

__DATA__
Any	Types::Standard	No	No	Anything. Absolutely anything.
ArrayLike	Types::TypeTiny	No	No	Arrayrefs and objects overloading arrayfication.
ArrayRef	Types::Standard	No	Yes	Arrayrefs.
Bool	Types::Standard	Yes	No	Booleans; the numbers or strings "0" and "1", the empty string, or undef. 
ClassName	Types::Standard	No	No	Any loaded package name.
CodeLike	Types::TypeTiny	No	No	Coderefs and objects overloading coderefification.
CodeRef	Types::Standard	No	No	Coderefs.
ConsumerOf	Types::Standard	No	Yes	An object that DOES a particular role.
CycleTuple	Types::Standard	No	Yes	An arrayref with a repeating pattern of constraints on its values.
Defined	Types::Standard	No	No	Any value other than undef.
Dict	Types::Standard	No	Yes	A hashref with constraints on each of its values.
Enum	Types::Standard	No	Yes	A string from an allowed set of strings.
FileHandle	Types::Standard	No	No	A reference where Scalar::Util::openhandle returns true, or a blessed object in the IO::Handle class.
GlobRef	Types::Standard	No	No	Globrefs
HashLike	Types::TypeTiny	No	No	Hashrefs and objects overloading hashrefification.
HashRef	Types::Standard	No	Yes	Hashrefs.
HasMethods	Types::Standard	No	Yes	An object that can do particular methods.
InstanceOf	Types::Standard	No	Yes	An object that isa particular class.
Int	Types::Standard	No	No	A whole number, either positive, negative, or zero.
IntRange	Types::Common::Numeric	No	Yes	An integer within a particular numeric range.
Item	Types::Standard	No	No	Any single item; effectively the same as Any.
LaxNum	Types::Standard	No	No	A number; relaxed constraint that allows "inf".
LowerCaseSimpleStr	Types::Common::String	Yes	No	A string less than 256 characters long with no line breaks or uppercase letters.
LowerCaseStr	Types::Common::String	Yes	No	A string with no uppercase letters.
Map	Types::Standard	No	Yes	A hashref with a constraint for the values and keys.
Maybe	Types::Standard	No	Yes	When parameterized, the same as its parameter, but also allows undef.
NegativeInt	Types::Common::Numeric	No	No	An integer below 0.
NegativeNum	Types::Common::Numeric	No	No	A number below 0.
NegativeOrZeroInt	Types::Common::Numeric	No	No	An integer below 0, or 0.
NegativeOrZeroNum	Types::Common::Numeric	No	No	A number below 0, or 0.
NonEmptySimpleStr	Types::Common::String	No	No	A string with more than 0 but less than 256 characters with no line breaks.
NonEmptyStr	Types::Common::String	No	No	A string with more than 0 characters.
Num	Types::Standard	No	No	The same as LaxNum or StrictNum depending on environment.
NumericCode	Types::Common::String	Yes	No	A string containing only digits.
NumRange	Types::Common::Numeric	No	Yes	A number within a particular numeric range.
Object	Types::Standard	No	No	A blessed object.
Optional	Types::Standard	No	Yes	Used in conjunction with Dict, Tuple, or CycleTuple.
OptList	Types::Standard	No	No	An arrayref of arrayrefs, where each of the inner arrayrefs are two values, the first value being a string.
Overload	Types::Standard	No	Yes	An overloaded object.
Password	Types::Common::String	No	No	A string at least 4 characters long and less than 256 characters long with no line breaks.
PositiveInt	Types::Common::Numeric	No	No	An integer above 0.
PositiveNum	Types::Common::Numeric	No	No	A number above 0.
PositiveOrZeroInt	Types::Common::Numeric	No	No	An integer above 0, or 0.
PositiveOrZeroNum	Types::Common::Numeric	No	No	An number above 0, or 0.
Ref	Types::Standard	No	Yes	Any reference.
RegexpRef	Types::Standard	No	No	A regular expression.
RoleName	Types::Standard	No	No	Any loaded package name where there is no `new` method.
ScalarRef	Types::Standard	No	Yes	Scalarrefs.
SimpleStr	Types::Common::String	No	No	A string with less than 256 characters with no line breaks.
SingleDigit	Types::Common::Numeric	No	No	A single digit number. This includes single digit negative numbers!
Str	Types::Standard	No	No	A string.
StrictNum	Types::Standard	No	No	A number; strict constaint.
StringLike	Types::TypeTiny	No	No	Strings and objects overloading stringification.
StrLength	Types::Common::String	No	Yes	A string with length in a particular range.
StrMatch	Types::Standard	No	Yes	A string matching a particular regular expression.
StrongPassword	Types::Common::String	No	No	A string at least 4 characters long and less than 256 characters long with no line breaks and at least one non-alphabetic character.
Tied	Types::Standard	No	Yes	A reference to a tied variable.
Tuple	Types::Standard	No	Yes	An arrayref with constraints on its values.
TypeTiny	Types::TypeTiny	Yes	No	Blessed objects in the Type::Tiny class.
Undef	Types::Standard	No	No	undef.
UpperCaseSimpleStr	Types::Common::String	Yes	No	A string less than 256 characters long with no line breaks or lowercase letters.
UpperCaseStr	Types::Common::String	Yes	No	A string with no lowercase letters.
Value	Types::Standard	No	No	Any non-reference value, including undef.
