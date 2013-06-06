package WebService::LiveJournal::Friend;

use strict;
use warnings;
use WebService::LiveJournal::Thingie;
our @ISA = qw/ WebService::LiveJournal::Thingie /;

# ABSTRACT: LiveJournal friend class
# VERSION

sub new
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless { }, $class;

  my %arg = @_;
  $self->{username} = $arg{username};  # req
  $self->{fullname} = $arg{fullname};  # req
  $self->{bgcolor} = $arg{bgcolor};  # req
  $self->{fgcolor} = $arg{fgcolor};  # req
  $self->{type} = $arg{type};    # opt
  $self->{groupmask} = $arg{groupmask};  # req

  return $self;
}

sub name { username(@_) }
sub username { $_[0]->{username} }
sub fullname { $_[0]->{fullname} }
sub bgcolor { $_[0]->{bgcolor} }
sub fgcolor { $_[0]->{fgcolor} }
sub type { $_[0]->{type} }
sub groupmask { $_[0]->{groupmask} }
sub mask { $_[0]->{groupmask} }

sub as_string { '[friend ' . $_[0]->{username} . ']' }

1;
