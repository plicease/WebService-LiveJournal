package WebService::LiveJournal::FriendGroup;

use strict;
use warnings;
use WebService::LiveJournal::Thingie;
our @ISA = qw/ WebService::LiveJournal::Thingie /;

# ABSTRACT: (Deprecated) LiveJournal friend group class
# VERSION

=head1 SYNOPSIS

 use WebService::LiveJournal;
 my $client = WebService::LiveJournal->new(
   username => $user,
   password => $pass,
 );
 
 foreach my $group (@{ $client->get_friend_groups })
 {
   # $group isa WS::LJ::FriendGroup
   ...
 }

Allow only members of groups "group1" and "group2" to read an event
specified by C<$itemid>:

 use WebService::LiveJournal;
 my $client = WebService::LiveJournal->new(
   username => $user,
   password => $pass,
 );
 
 my(@groups) = grep { $_->name =~ /^group[12]$/ } @{ $client->get_friend_groups };
 
 my $event = $client->get_event($itemid);
 $event->set_access('group', @groups);
 $event->update;

=head1 DESCRIPTION

B<NOTE>: This distribution is deprecated.  It uses the outmoded XML-RPC protocol.
LiveJournal has also been compromised.  I recommend using DreamWidth instead
(L<https://www.dreamwidth.org/>) which is in keeping with the original philosophy
LiveJournal regarding advertising.

This class represents a friend group on the LiveJournal server.
Friend groups can be used to restrict the readability of events.

=cut

sub new
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless {}, $class;
  my %arg = @_;
  $self->{public} = $arg{public};
  $self->{name} = $arg{name};
  $self->{id} = $arg{id};
  $self->{sortorder} = $arg{sortorder};
  return $self;
}

=head1 ATTRIBUTES

=head2 name

The name of the group.

=head2 id

The LiveJournal internal id for the friend groups.
Friend groups are unique to a user, not to the server
itself, so to get a unique key you must combine
the user and the friend group id.

=head2 public

=head2 sortorder

=cut

sub public { $_[0]->{public} }
sub name { $_[0]->{name} }
sub id { $_[0]->{id} }
sub sortorder { $_[0]->{sortorder} }

sub as_string { 
  my $self = shift;
  my $name = $self->name;
  my $id = $self->id;
  my $mask = $self->mask;
  my $bin = sprintf "%b", $mask;
  "[friendgroup $name ($id $mask $bin)]"; 
}

=head2 mask

The mask used to compute the usemask when setting
the access control on the event.  Normally you should
not need to use this directly.

=cut

sub mask
{
  my $self = shift;
  my $id = $self->id;
  2**$id;
}

1;

=head1 SEE ALSO

L<WebService::LiveJournal>,

=cut
