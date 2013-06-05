package WebService::LiveJournal::FriendList;

use strict;
use warnings;
use WebService::LiveJournal::List;
use WebService::LiveJournal::Friend;
our @ISA = qw/ WebService::LiveJournal::List /;

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

sub toStr
{
  my $self = shift;
  my $str = '[friendlist ';
  foreach my $friend (@{ $self })
  {
    $str .= $friend->toStr;
  }
  $str .= ']';
  $str;
}

1;
