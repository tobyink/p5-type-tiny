package Type::Exception;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Exception::AUTHORITY = 'cpan:TOBYINK';
	$Type::Exception::VERSION   = '0.005_02';
}

use overload
	q[""]    => sub { $_[0]->to_string },
	fallback => 1,
;

sub new
{
	my $class = shift;
	my %params = (@_==1) ? %{$_[0]} : @_;
	return bless \%params, $class;
}

sub throw
{
	my $class = shift;
	die( $class->new(@_) );
}

sub message    { $_[0]{message} };
sub to_string  { shift->message };

package Type::Exception::Assertion;

BEGIN {
	$Type::Exception::Assertion::AUTHORITY = 'cpan:TOBYINK';
	$Type::Exception::Assertion::VERSION   = '0.005_02';
	our @ISA = qw(Type::Exception);
}

sub type       { $_[0]{type} };
sub value      { $_[0]{value} };

1;
