package Net::Lumberjack::Frame::Compressed;

use Moose;

# ABSTRACT: class for parsing Lumberjack compressed frames
# VERSION

extends 'Net::Lumberjack::Frame';

use Compress::Zlib;

has 'type' => ( is => 'rw', isa => 'Str', default => 'C' );
has 'stream' => ( is => 'rw', isa => 'Maybe[Str]' );

has 'payload' => (
  is => 'rw', isa => 'Str', lazy => 1,
  'default' => sub {
    my $self = shift;
    my $compressed = compress( $self->stream );
    my $len = length($compressed);
    return pack('N', $len).$compressed;
  },
);

sub _read_payload {
	my ( $self, $fh ) = @_;
  $self->stream( uncompress $self->_read_data($fh) );
  return;
}

1;

