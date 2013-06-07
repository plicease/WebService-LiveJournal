package WebService::LiveJournal::Thingie;

use strict;
use warnings;
use overload '""' => sub { $_[0]->as_string };

# ABSTRACT: base class for WebService::LiveJournal classes
# VERSION

sub client
{
  my($self, $new_value) = @_;
  $self->{client} = $new_value if defined $new_value;
  $self->{client};
}

1;

=head1 SEE ALSO

L<WebService::LiveJournal>

=cut
