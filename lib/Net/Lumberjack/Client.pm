package Net::Lumberjack::Client;

use Moose;

# ABSTRACT: a client for the lumberjack protocol
# VERSION

use IO::Socket::INET6;
use IO::Socket::SSL;
use Net::Lumberjack::Writer;

has 'host' => ( is => 'ro', isa => 'Str', default => '127.0.0.1' );
has 'port' => ( is => 'ro', isa => 'Int', default => 5044 );
has 'keepalive' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'frame_format' => ( is => 'ro', isa => 'Maybe[Str]' );

has 'max_window_size' => ( is => 'ro', isa => 'Maybe[Int]' );

has '_conn' => ( is => 'rw', isa => 'Maybe[IO::Handle]' );
has '_writer' => ( is => 'rw', isa => 'Maybe[Net::Lumberjack::Writer]' );

has 'use_ssl' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'ssl_verify' => ( is => 'ro', isa => 'Bool', default => 1 );
has 'ssl_ca_file' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'ssl_ca_path' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'ssl_version' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'ssl_hostname' => ( is => 'ro', isa => 'Maybe[Str]' );

has 'ssl_cert' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'ssl_key' => ( is => 'ro', isa => 'Maybe[Str]' );

sub _connect {
  my $self = shift;
  my $sock;
  if( $self->use_ssl ) {
    $sock = IO::Socket::SSL->new(
      PeerHost => $self->host,
      PeerPort => $self->port,
      SSL_verify_mode => $self->ssl_verify ?
        SSL_VERIFY_PEER : SSL_VERIFY_NONE ,
      defined $self->ssl_version ? 
        ( SSL_version => $self->ssl_version ) : (),
      defined $self->ssl_ca_file ? 
        ( SSL_ca_file => $self->ssl_ca_file ) : (),
      defined $self->ssl_ca_path ? 
        ( SSL_ca_file => $self->ssl_ca_path ) : (),
      defined $self->ssl_cert && defined $self->ssl_key ?
        (
          SSL_use_cert => 1,
          SSL_cert_file => $self->ssl_cert,
          SSL_key_file => $self->ssl_key,
        ) : (),
      defined $self->ssl_hostname ?
        ( SSL_hostname => $self->ssl_hostname ) : (),
    ) or die('could not enstablish ssl connection to '.$self->host.':'.$self->port.': '.$SSL_ERROR);
  } else {
    $sock = IO::Socket::INET6->new(
      Proto => 'tcp',
      PeerAddr => $self->host,
      PeerPort => $self->port,
    ) or die('could not connect to '.$self->host.':'.$self->port.': '.$!);
  }
  $self->_conn( $sock );

  my $writer = Net::Lumberjack::Writer->new(
    handle => $sock,
    defined $self->max_window_size ?
      ( max_window_size => $self->max_window_size ) : (),
    defined $self->frame_format ?
      ( frame_format => $self->frame_format ) : (),
  );
  $self->_writer( $writer );

  return;
}

sub _ensure_connected {
  my $self = shift;

  if( defined $self->_conn
      && $self->_conn->connected
      && defined $self->_writer ) {
    return;
  }

  $self->_connect;

  return;
}
sub _reconnect {
  my $self = shift;

  $self->_disconnect;
  $self->_connect;

  return;
}

sub _disconnect {
  my $self = shift;

  if( defined $self->_conn ) {
    $self->_conn->close();
    $self->_conn( undef );
  }
  $self->_writer( undef );

  return;
}

sub send_data {
  my $self = shift;

  $self->_ensure_connected;

  eval {
    local $SIG{PIPE} = sub { die "connection reset (broken pipe)" };
    $self->_writer->send_data( @_ );
  };
  my $e = $@;
  if( $e ) {
    if( $e =~ /^connection reset/
        || $e =~ /^lost connection/ ) {
      $self->_disconnect; # try to cleanup
    }
    die $e;
  }

  if( ! $self->keepalive ) {
    $self->_disconnect;
  }
  return;
}

1;

