package Net::Lumberjack::Frame::JSON;

use Moose;

# ABSTRACT: class for parsing Lumberjack JSON frames
# VERSION

extends 'Net::Lumberjack::Frame';

use JSON;

has 'type' => ( is => 'ro', isa => 'Str', default => 'J' );
has 'version' => ( is => 'rw', isa => 'Int', default => 2 );

has 'seq' => ( is => 'rw', isa => 'Maybe[Int]' );
has 'data' => ( is => 'rw', isa => 'Maybe[HashRef]' );

has 'payload' => (
  is => 'rw', isa => 'Str', lazy => 1,
  default => sub {
    my $self = shift;
    my $json_str = encode_json( $self->data );
    my $len = length($json_str);
    return pack('NN', $self->seq, $len).$json_str;
  },
);

sub _read_payload {
	my ( $self, $fh ) = @_;

  $self->seq( $self->_read_uint32($fh) );
  $self->data( decode_json($self->_read_data($fh)) );

  return;
}


1;

