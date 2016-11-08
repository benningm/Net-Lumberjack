package Net::Lumberjack::Writer;

use Moose;

# ABSTRACT: class to generate lumberjack frame stream
# VERSION

use Net::Lumberjack::Frame;
use Net::Lumberjack::Frame::WindowSize;
use Net::Lumberjack::Frame::JSON;
use Net::Lumberjack::Frame::Compressed;

has 'handle' => ( is => 'ro', required => 1 );

has 'seq' => (
  is => 'ro', isa => 'Int', default => 0,
  traits => [ 'Counter' ],
  handles => {
    next_seq => 'inc',
  },
);
has 'last_ack' => ( is => 'rw', isa => 'Int', default => 0 );
has 'max_window_size' => ( is => 'rw', isa => 'Int', default => 50 );

has 'current_window_size' => ( is => 'rw', isa => 'Int', default => 0 );

sub set_window_size {
	my ( $self, $size ) = @_;
  if( $self->current_window_size != $size ) {
    my $window = Net::Lumberjack::Frame::WindowSize->new(
      window_size => $size,
    );
    $self->handle->print( $window->as_string );
    $self->current_window_size( $size );
  }
  return;
}

sub send_data {
	my ( $self, @data ) = @_;

  if( ! @data ) {
    return;
  }

  while(@data) {
    my $num_bulk = scalar(@data) > $self->max_window_size ?
      $self->max_window_size : scalar(@data);
    $self->set_window_size( $num_bulk );
    my $stream = '';
    for( my $i = 0 ; $i < $num_bulk ; $i++ ) {
      my $frame = Net::Lumberjack::Frame::JSON->new(
        seq => $self->next_seq,
        data => shift(@data),
      );
      $stream .= $frame->as_string;
    }
    my $compressed = Net::Lumberjack::Frame::Compressed->new(
      stream => $stream,
    );
    $self->handle->print( $compressed->as_string );
    $self->wait_for_ack( $self->seq );
  }

  return;
}

sub wait_for_ack {
  my ( $self, $wait_for_seq ) = @_;
  while( my $frame = Net::Lumberjack::Frame->new_from_fh($self->handle) ) {
    if( ref($frame) eq 'Net::Lumberjack::Frame::Ack' ) {
      $self->last_ack( $frame->seq );
    }
    if( $self->last_ack >= $wait_for_seq ) {
      last;
    }
  }
  return;
}

1;

