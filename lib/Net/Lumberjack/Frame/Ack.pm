package Net::Lumberjack::Frame::Ack;

use Moose;

# ABSTRACT: class for parsing Lumberjack ACK frames
# VERSION

extends 'Net::Lumberjack::Frame';

has 'type' => ( is => 'rw', isa => 'Str', 'default' => 'A' );
has 'seq' => ( is => 'rw', isa => 'Maybe[Int]' );

has 'payload' => (
  is => 'rw', isa => 'Str', lazy => 1,
  'default' => sub {
    my $self = shift;
    return pack('N', $self->seq);
  },
);

sub _read_payload {
	my ( $self, $fh ) = @_;
  $self->seq( $self->_read_uint32($fh) );
  return;
}

1;

