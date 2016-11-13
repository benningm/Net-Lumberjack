package Net::Lumberjack::Frame;

use Moose;

# ABSTRACT: class for parsing Lumberjack protocol frames
# VERSION

use Net::Lumberjack::Frame::WindowSize;
use Net::Lumberjack::Frame::Compressed;
use Net::Lumberjack::Frame::Ack;
use Net::Lumberjack::Frame::Data;
use Net::Lumberjack::Frame::JSON;

has 'version' => ( is => 'rw', isa => 'Int', default => 1 );
has 'type' => ( is => 'rw', isa => 'Str', required => 1 );
has 'payload' => ( is => 'rw', isa => 'Str', lazy => 1, default => '' );

our %FRAME_TYPES = (
  'A' => 'Ack',
  'W' => 'WindowSize',
  'C' => 'Compressed',
  'D' => 'Data',
  'J' => 'JSON',
);

sub new_from_fh {
	my ( $class, $fh ) = ( shift, shift );
	my ( $version, $type );
  # EOF not supported by IO::Socket::SSL
  #if( $fh->eof ) {
  #  return;
  #}
  if( ! $fh->read( $version, 1 ) || ! $fh->read( $type, 1 ) ) {
    die('lost connection');
	}

  if( ! defined $FRAME_TYPES{$type} ) {
    die('Unknown Lumberjack frame type: '.$type.'('.ord($type).')');
  }

  my $type_class = $class.'::'.$FRAME_TYPES{$type};
	my $obj = $type_class->new(
    'version' => $version,
    'type' => $type,
    @_
  );
  $obj->_read_payload($fh);
  return $obj;
}

sub _read_payload {
	my ( $self, $fh ) = @_;
  die('NOT IMPLEMENTED');
}

sub _read_uint32 {
	my ( $self, $fh ) = @_;
  my $buf;
  $fh->read( $buf, 4 );
  my $int = unpack 'N', $buf;
  return $int;
}

sub _read_data {
	my ( $self, $fh ) = @_;
  my $len = $self->_read_uint32( $fh );
  my $data;
  $fh->read( $data, $len );
  return $data;
}

sub as_string {
  my $self = shift;
  return pack('CC', ord($self->version), ord($self->type)).$self->payload;
}

1;

