package Net::Lumberjack::Frame::WindowSize;

use Moose;

# ABSTRACT: class for parsing Lumberjack window size frames
# VERSION

extends 'Net::Lumberjack::Frame';

has 'type' => ( is => 'rw', isa => 'Str', default => 'W' );
has 'window_size' => ( is => 'rw', isa => 'Maybe[Int]' );

has 'payload' => (
  is => 'rw', isa => 'Str', lazy => 1,
  'default' => sub {
    my $self = shift;
    return pack('N', $self->window_size);
  },
);

sub _read_payload {
	my ( $self, $fh ) = @_;
  $self->window_size( $self->_read_uint32($fh) );
  return;
}

1;

