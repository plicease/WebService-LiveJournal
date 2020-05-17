package WebService::LiveJournal::Thingie;

use strict;
use warnings;
use overload '""' => sub { $_[0]->as_string };

# ABSTRACT: (Deprecated) base class for WebService::LiveJournal classes
# VERSION

=head1 DESCRIPTION

B<NOTE>: This distribution is deprecated.  It uses the outmoded XML-RPC protocol.
LiveJournal has also been compromised.  I recommend using DreamWidth instead
(L<https://www.dreamwidth.org/>) which is in keeping with the original philosophy
LiveJournal regarding advertising.

=cut

sub client
{
  my($self, $new_value) = @_;
  $self->{client} = $new_value if defined $new_value;
  $self->{client};
}

sub error { shift->client->error }

1;

=head1 SEE ALSO

L<WebService::LiveJournal>

=cut
