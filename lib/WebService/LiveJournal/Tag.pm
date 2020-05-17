package WebService::LiveJournal::Tag;

use strict;
use warnings;
use WebService::LiveJournal::Thingie;
our @ISA = qw/ WebService::LiveJournal::Thingie /;

# ABSTRACT: (Deprecated) A LiveJournal tag
# VERSION

=head1 SYNOPSIS

 use WebService::LiveJournal;
 my $client = WebService::LiveJournal->new( ... );
 my @tags = $client->get_user_tags;
 
 # print out each tag name, one per line
 say $_->name for @tags;

=head1 DESCRIPTION

B<NOTE>: This distribution is deprecated.  It uses the outmoded XML-RPC protocol.
LiveJournal has also been compromised.  I recommend using DreamWidth instead
(L<https://www.dreamwidth.org/>) which is in keeping with the original philosophy
LiveJournal regarding advertising.

Instances of this class represent LiveJournal tags.  They can
be fetched from the LiveJournal server using the C<get_user_tags>
client method.  That method takes one optional argument, which
is the journal to use.  If the journal name is not specified
then it will use the logged in user's journal.

=cut

sub new
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless { payload => shift }, $class;
  return $self;
}

=head1 ATTRIBUTES

=head2 name

The tag name.

=cut

sub name { shift->{payload}->{name} }

=head2 display

If present and on, indicates that this tag is visible to the S2 style system. Tags with 
this value set to off are still usable, they're just not exposed to S2.

=cut

sub display { shift->{payload}->{display} }

=head2 security_level

The security (visibility) of the tag being returned. This can be one of 'public', 
'private', 'friends', or 'group'.

=cut

sub security_level { shift->{payload}->{security_level} }

=head2 uses

Number of times the tag has been used.

=cut

sub uses { shift->{payload}->{uses} }

=head2 security

Shows the breakdown of use by security category.

=over 4

=item $tag-E<gt>security-E<gt>{public}

The number of times this tag has been used on a public post.

=item $tag-E<gt>security-E<gt>{private}

The number of times this tag has been used on a private post.

=item $tag-E<gt>security-E<gt>{friends}

The number of times this tag has been used on a Friends-only post.

=item $tag-E<gt>security-E<gt>{groups}

Hash containing the breakdown by group, keys are the group name and values are the counts.

=back

=cut

sub security { shift->{payload}->{security} }


1;
