package WebService::LiveJournal;

use strict;
use warnings;
use v5.10;
use base qw( WebService::LiveJournal::Client );

# ABSTRACT: (Deprecated) Interface to the LiveJournal API
# VERSION

sub _set_error
{
  my($self, $message) = @_;
  $self->SUPER::_set_error($message);
  die $message;
}

1;

