package WebService::LiveJournal::EventList;

use strict;
use warnings;
use WebService::LiveJournal::List;
use WebService::LiveJournal::Event;
our @ISA = qw/ WebService::LiveJournal::List /;

sub init
{
  my $self = shift;
  my %arg = @_;
  
  if(defined $arg{response})
  {
    my $events = $arg{response}->value->{events};
    if(defined $events)
    {
      foreach my $e (@{ $events })
      {
        $self->push(new WebService::LiveJournal::Event(client => $arg{client}, %{ $e }));
      }
    }
  }
  
  return $self;
}

sub toStr
{
  my $self = shift;
  my $str = '[eventlist ';
  foreach my $friend (@{ $self })
  {
    $str .= $friend->toStr;
  }
  $str .= ']';
  $str;
}

1;
