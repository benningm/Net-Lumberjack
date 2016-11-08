package Net::Lumberjack::Client;

use Moose;

# ABSTRACT: a client for the lumberjack protocol
# VERSION

use IO::Socket::INET6;
use Net::Lumberjack::Writer;

has 'host' => ( is => 'ro', isa => 'Str', default => '127.0.0.1' );
has 'port' => ( is => 'ro', isa => 'Int', default => 5044 );

has 'handle' => (
  is => 'ro', lazy => 1,
  default => sub {
    my $self = shift;
    my $sock = IO::Socket::INET6->new(
      Proto => 'tcp',
      PeerAddr => $self->host,
      PeerPort => $self->port,
    ) or die('could not connect to '.$self->host.':'.$self->port.': '.$!);
    return $sock;
  },
);

has '_writer' => (
  is => 'ro', isa => 'Net::Lumberjack::Writer',
  lazy => 1,
  default => sub {
    my $self = shift;
    return Net::Lumberjack::Writer->new( handle => $self->handle );
  },
  handles => [ 'send_data' ],
);

1;

