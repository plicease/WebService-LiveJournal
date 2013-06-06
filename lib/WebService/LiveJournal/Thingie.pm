package WebService::LiveJournal::Thingie;

use strict;
use warnings;
use overload '""' => sub { $_[0]->as_string };

sub setclient { $_[0]->{client} = $_[1] }
sub client { $_[0]->{client} }

1;
