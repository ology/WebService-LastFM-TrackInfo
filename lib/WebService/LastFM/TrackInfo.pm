package WebService::LastFM::TrackInfo;

# ABSTRACT: Access to *.getInfo slices of the last.fm API

our $VERSION = '0.0204';

use Moo;
use strictures 2;
use namespace::clean;

use Carp;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json);
use Mojo::URL;
use Try::Tiny;

=head1 SYNOPSIS

  use WebService::LastFM::TrackInfo;

  my $w = WebService::LastFM::TrackInfo->new(api_key => 'abcdef123456');
  my $r = $w->fetch(
    artist => 'Led Zeppelin',
    track  => 'Kashmir',
  );
  print Dumper $r; # Do something cool with the result!

  $w = WebService::LastFM::TrackInfo->new(
    api_key => 'abcdef123456',
    method  => 'album.getInfo',
  );
  $r = $w->fetch(
    artist => 'Led Zeppelin',
    album  => 'Presence',
  );

=head1 DESCRIPTION

C<WebService::LastFM::TrackInfo> provides access to a couple *.getInfo
API slices: track, artist and album.

=head1 ATTRIBUTES

=head2 api_key

Your required, last.fm API authorization key.

Default: C<undef>

=cut

has api_key => (
    is       => 'ro',
    required => 1,
);

=head2 method

The required method string ("track", "artist", or "album").

Default: C<track>

=cut

has method => (
    is      => 'ro',
    default => sub { 'track' },
);

=head2 format

The last.fm API response format ("xml" or "json")

Default: C<json>

=cut

has format => (
    is      => 'ro',
    default => sub { 'json' },
);

=head2 base

The base URL.

Default: C<http://ws.audioscrobbler.com>

=cut

has base => (
    is      => 'rw',
    default => sub { 'http://ws.audioscrobbler.com' },
);

=head2 version

The API version.

Default: C<2.0>

=cut

has version => (
    is      => 'ro',
    default => sub { '2.0' },
);

=head2 ua

The user agent.

Default: C<Mojo::UserAgent-E<gt>new>

=cut

has ua => (
    is      => 'rw',
    default => sub { Mojo::UserAgent->new },
);

=head1 METHODS

=head2 new

  $w = WebService::LastFM::TrackInfo->new(
      api_key => $api_key,
      method  => $method,
      format  => $format,
  );

Create a new C<WebService::LastFM::TrackInfo> object with your
required B<api_key> argument.

=head2 fetch

  $r = $w->fetch(artist => $artist, track => $track);
  $r = $w->fetch(artist => $artist, album => $album); # for method => album
  $r = $w->fetch(artist => $artist); # for method => artist

Fetch the results given the B<artist>, B<album> or B<track>.

=cut

sub fetch {
    my ( $self, %args ) = @_;

    croak 'No artist provided' unless $args{artist};
    croak 'No track provided' if $self->method eq 'track.getInfo' && !$args{track};
    croak 'No album provided' if $self->method eq 'album.getInfo' && !$args{album};

    my $url = Mojo::URL->new($self->base)
        ->path($self->version)
        ->query(
            %args,
            api_key => $self->api_key,
            method  => $self->method . '.getInfo',
            format  => $self->format,
        );

    my $tx = $self->ua->get($url);

    my $data = $self->_handle_response($tx);

    return $data;
}

sub _handle_response {
    my ($self, $tx) = @_;

    my $data;

    my $res = $tx->result;

    if ( $res->is_success ) {
        my $body = $res->body;

        if ($self->format eq 'json') {
            try {
                $data = decode_json($body);
            }
            catch {
                croak $body, "\n";
            };
        }
        else {
            $data = $body;
        }
    }
    else {
        croak 'Connection error: ', $res->message;
    }

    return $data;
}

1;
__END__

=head1 SEE ALSO

The F<t/*> tests

The F<eg/*> programs

L<https://www.last.fm/api/show/track.getInfo>

L<Moo>

L<Mojo::JSON>

L<Mojo::URL>

L<Mojo::UserAgent>

L<Try::Tiny>

L<Net::LastFMAPI> - Contains this functionality I guess? Broken for me...

=cut
