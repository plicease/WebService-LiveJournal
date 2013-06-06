package WebService::LiveJournal;

use strict;
use warnings;
use v5.10;
use base qw( WebService::LiveJournal::Client );

# ABSTRACT: Interface to the LiveJournal API via XML-RPC
# VERSION

=head1 SYNOPSIS

 use WebService::LiveJournal

=head1 DESCRIPTION

This distribution provides an Perl interface to the LiveJournal client API.

Currently, the main interface is through the client class
L<WebService::LiveJournal::Client>. I intend to use WebService::LiveJournal
in the future as a class which works like WS::LJ::Client except that it
throws exceptions instead of returning undef.

=head1 HISTORY

The code in this distribution was written many years ago to sync my website
with my LiveJournal.  It has some ugly warts and its interface was not well 
planned or thought out, it has many omissions and contains much tat is apocryphal 
(or at least wildly inaccurate), but it (possibly) scores over the older 
LiveJournal modules on CPAN in that it has been used in production for 
many many years with very little maintenance required, and at the time of 
its original writing the documentation for those modules was sparse or misleading.

=cut

sub _set_error
{
  my($self, $message) = @_;
  die $message;
}

1;

=head1 SEE ALSO

L<WebService::LiveJournal::Client>,
L<http://www.livejournal.com/doc/server/index.html>,
L<Net::LiveJournal>,
L<LJ::Simple>

=cut

