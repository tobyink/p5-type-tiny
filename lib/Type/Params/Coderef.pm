package Type::Params::Coderef;

use 5.006001;
use strict;
use warnings;

BEGIN {
	if ( $] < 5.008 ) { require Devel::TypeTiny::Perl56Compat }
	if ( $] < 5.010 ) { require Devel::TypeTiny::Perl58Compat }
}

BEGIN {
	$Type::Params::Coderef::AUTHORITY  = 'cpan:TOBYINK';
	$Type::Params::Coderef::VERSION    = '1.015_003';
}

$Type::Params::Coderef::VERSION =~ tr/_//d;

use Eval::TypeTiny ();

sub new {
	my $class = shift;

	my %self  = @_ == 1 ? %{$_[0]} : @_;
	$self{env}          ||= {};
	$self{code}         ||= [];
	$self{placeholders} ||= {};

	bless \%self, $class;
}

sub code        { join( "\n", @{ $_[0]{code} } ) }
sub description { $_[0]{description} }

sub add_line {
	my $self = shift;
	my $indent = $self->{indent} || '';

	push @{ $self->{code} }, map { $indent . $_ } map { split /\n/ } @_;

	$self;
}

sub add_gap {
	push @{ $_[0]{code} }, '';
}

sub add_placeholder {
	my ( $self, $for ) = ( shift, @_ );
	my $indent = $self->{indent} || '';

	$self->{placeholders}{$for} = @{ $self->{code} };
	push @{ $self->{code} }, "$indent# placeholder for $for";

	$self;
}

sub fill_placeholder {
	my ( $self, $for, @lines ) = ( shift, @_ );

	my $line_number = delete $self->{placeholders}{$for};
	splice( @{ $self->{code} }, $line_number, 1, @lines );

	$self;
}

sub add_variable {
	my ( $self, $suggested_name, $reference ) = ( shift, @_ );
	
	my $actual_name = $suggested_name;
	my $i = 0;
	while ( exists $self->{env}{$actual_name} ) {
		$actual_name = sprintf '%s_%d', $suggested_name, ++$i;
	}

	$self->{env}{$actual_name} = $reference;

	$actual_name;
}

sub finalize {}

sub compile {
	my $self = shift;

	$self->{finalized}++ or $self->finalize();

	return Eval::TypeTiny::eval_closure(
		source       => $self->code,
		environment  => $self->{env},
		description  => $self->description,
	);
}

1;
