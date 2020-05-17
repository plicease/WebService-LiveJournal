package WebService::LiveJournal::RPC;

use strict;
use warnings;
use Exporter;
use RPC::XML;
use RPC::XML::ParserFactory;
use RPC::XML::Client;
our @ISA = qw/ Exporter /;
our @EXPORT_OK = qw/ xml2hashref xml2hash /;

# ABSTRACT: (Deprecated) RPC utilities for WebService::LiveJournal
# VERSION

=head1 DESCRIPTION

B<NOTE>: This distribution is deprecated.  It uses the outmoded XML-RPC protocol.
LiveJournal has also been compromised.  I recommend using DreamWidth instead
(L<https://www.dreamwidth.org/>) which is in keeping with the original philosophy
LiveJournal regarding advertising.

=cut

my $parser = new RPC::XML::ParserFactory;

sub xml2hashref
{
  my $xml = shift;
  my $response = $parser->parse($xml);
  my $struct = $response->value;
  my $hash = $struct->value;
}

sub xml2hash { %{ xml2hashref(@_) } }

1;

=head1 SEE ALSO

L<WebService::LiveJournal>

=cut
