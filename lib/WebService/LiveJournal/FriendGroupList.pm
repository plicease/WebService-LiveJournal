package WebService::LiveJournal::FriendGroupList;

use strict;
use warnings;
use WebService::LiveJournal::List;
use WebService::LiveJournal::FriendGroup;
our @ISA = qw/ WebService::LiveJournal::List /;

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

sub toStr
{
  my $self = shift;
  my $str = "[friendgrouplist \n";
  foreach my $friend (@{ $self })
  {
    $str .= "\t" . $friend->toStr . "\n";
  }
  $str .= ']';
  $str;
}

1;
