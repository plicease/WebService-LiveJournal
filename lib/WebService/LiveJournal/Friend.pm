package WebService::LiveJournal::Friend;

use strict;
use warnings;
use WebService::LiveJournal::Thingie;
our @ISA = qw/ WebService::LiveJournal::Thingie /;

# ABSTRACT: (Deprecated) LiveJournal friend class
# VERSION

=head1 SYNOPSIS

 use WebService::LiveJournal;
 my $client = WebService::LiveJournal->new(
   username => $user,
   password => $pass,
 );
 
 # get the list of your friends
 foreach my $friend (@{ $client->get_friend })
 {
   # $friend isa WS::LJ::Friend
   ...
 }
 
 # get the list of your stalkers, er... I mean people who have you as a friend:
 foreach my $friend (@{ $client->get_friend_of })
 {
   # $friend isa WS::LJ::Friend
   ...
 }

=head1 DESCRIPTION

B<NOTE>: This distribution is deprecated.  It uses the outmoded XML-RPC protocol.
LiveJournal has also been compromised.  I recommend using DreamWidth instead
(L<https://www.dreamwidth.org/>) which is in keeping with the original philosophy
LiveJournal regarding advertising.

This class represents a friend or user on the LiveJournal server.

=cut

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

=head1 ATTRIBUTES

=head2 username

The name of the user

=head2 fullname

The full name (First Last) of the user

=head2 bgcolor

The background color for the user

=head2 fgcolor

The foreground color for the user

=head2 type

The type of user

=head2 mask

The group mask of the user

=cut

sub name { shift->username(@_) }
sub username { $_[0]->{username} }
sub fullname { $_[0]->{fullname} }
sub bgcolor { $_[0]->{bgcolor} }
sub fgcolor { $_[0]->{fgcolor} }
sub type { $_[0]->{type} }
sub groupmask { $_[0]->{groupmask} }
sub mask { $_[0]->{groupmask} }

sub as_string { '[friend ' . $_[0]->{username} . ']' }

1;

=head1 SEE ALSO

L<WebService::LiveJournal>,

=cut
