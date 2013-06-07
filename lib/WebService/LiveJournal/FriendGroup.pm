package WebService::LiveJournal::FriendGroup;

use strict;
use warnings;
use WebService::LiveJournal::Thingie;
our @ISA = qw/ WebService::LiveJournal::Thingie /;

# ABSTRACT: LiveJournal friend group class
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

=head1 DESCRIPTION

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

=head2 $group-E<gt>public

=head2 $group-E<gt>name

=head2 $group-E<gt>id

=head2 $group-E<gt>sortorder

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
