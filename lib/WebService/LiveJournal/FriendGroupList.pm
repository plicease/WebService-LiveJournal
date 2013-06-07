package WebService::LiveJournal::FriendGroupList;

use strict;
use warnings;
use WebService::LiveJournal::List;
use WebService::LiveJournal::FriendGroup;
our @ISA = qw/ WebService::LiveJournal::List /;

# ABSTRACT: List of LiveJournal friend groups
# VERSION

=head1 DESCRIPTION

List of friend groups returned from L<WebService::LiveJournal>.
See L<WebService::LiveJournal::FriendGroup> for how to use
this class.

=cut

sub init
{
  my $self = shift;
  my %arg = @_;
  
  if(defined $arg{response})
  {
    foreach my $f (@{ $arg{response}->value->{friendgroups} })
    {
      $self->push(new WebService::LiveJournal::FriendGroup(%{ $f }));
    }
  }
  
  return $self;
}

sub as_string
{
  my $self = shift;
  my $str = "[friendgrouplist \n";
  foreach my $friend (@{ $self })
  {
    $str .= "\t" . $friend->as_string . "\n";
  }
  $str .= ']';
  $str;
}

1;

=head1 SEE ALSO

L<WebService::LiveJournal>,

=cut
