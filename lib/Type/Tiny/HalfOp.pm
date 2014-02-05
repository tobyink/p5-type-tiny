package Type::Tiny::HalfOp;
use strict;
use warnings;

use overload ();

sub new {
	my ($class, $op, $param, $type) = @_;
	bless {
		op => $op,
		param => $param,
		type => $type,
	}, $class;
}

sub complete {
	my ($self, $type) = @_;
	my $complete_type = $type->parameterize(@{$self->{param}});
	my $method = overload::Method($complete_type, $self->{op});
	$complete_type->$method($self->{type});
}

1;
