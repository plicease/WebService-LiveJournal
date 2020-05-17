package WebService::LiveJournal::FriendList;

use strict;
use warnings;
use WebService::LiveJournal::List;
use WebService::LiveJournal::Friend;
our @ISA = qw/ WebService::LiveJournal::List /;

# ABSTRACT: (Deprecated) List of LiveJournal friends
# VERSION

=head1 DESCRIPTION

B<NOTE>: This distribution is deprecated.  It uses the outmoded XML-RPC protocol.
LiveJournal has also been compromised.  I recommend using DreamWidth instead
(L<https://www.dreamwidth.org/>) which is in keeping with the original philosophy
LiveJournal regarding advertising.

List of friends returned from L<WebService::LiveJournal>.
See L<WebService::LiveJournal::Friend> for how to use
this class.

=cut

sub init
{
  my $self = shift;
  my %arg = @_;
  
  if(defined $arg{response})
  {
    my $friends = $arg{response}->value->{friends};
    my $friendofs = $arg{response}->value->{friendofs};
    if(defined $friends)
    {
      foreach my $f (@{ $friends })
      {
        $self->push(new WebService::LiveJournal::Friend(%{ $f }));
      }
    }
    if(defined $friendofs)
    {
      foreach my $f (@{ $friendofs })
      {
        $self->push(new WebService::LiveJournal::Friend(%{ $f }));
      }
    }
  }
  
  if(defined $arg{response_list})
  {
    foreach my $f (@{ $arg{response_list} })
    {
      $self->push(new WebService::LiveJournal::Friend(%{ $f }));
    }
  }
  
  return $self;
}

sub as_string
{
  my $self = shift;
  my $str = '[friendlist ';
  foreach my $friend (@{ $self })
  {
    $str .= $friend->as_string;
  }
  $str .= ']';
  $str;
}

1;

=head1 SEE ALSO

L<WebService::LiveJournal>,

=cut
