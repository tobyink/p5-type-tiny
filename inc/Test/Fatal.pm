#line 1
use strict;
use warnings;
package Test::Fatal;
{
  $Test::Fatal::VERSION = '0.010';
}
# ABSTRACT: incredibly simple helpers for testing code with exceptions


use Carp ();
use Try::Tiny 0.07;

use base 'Exporter';

our @EXPORT    = qw(exception);
our @EXPORT_OK = qw(exception success dies_ok lives_ok);


sub exception (&) {
  my $code = shift;

  return try {
    $code->();
    return undef;
  } catch {
    return $_ if $_;

    my $problem = defined $_ ? 'false' : 'undef';
    Carp::confess("$problem exception caught by Test::Fatal::exception");
  };
}


sub success (&;@) {
  my $code = shift;
  return finally( sub {
    return if @_; # <-- only run on success
    $code->();
  }, @_ );
}


my $Tester;

# Signature should match that of Test::Exception
sub dies_ok (&;$) {
  my $code = shift;
  my $name = shift;

  require Test::Builder;
  $Tester ||= Test::Builder->new;

  my $ok = $Tester->ok( exception( \&$code ), $name );
  $ok or $Tester->diag( "expected an exception but none was raised" );
  return $ok;
}

sub lives_ok (&;$) {
  my $code = shift;
  my $name = shift;

  require Test::Builder;
  $Tester ||= Test::Builder->new;

  my $ok = $Tester->ok( !exception( \&$code ), $name );
  $ok or $Tester->diag( "expected return but an exception was raised" );
  return $ok;
}

1;

__END__
#line 212

