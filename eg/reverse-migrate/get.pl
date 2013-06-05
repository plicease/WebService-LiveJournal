use strict;
use warnings;
use 5.012;
use autodie;
use NX;
use WebService::LiveJournal::Client;
use YAML qw( Dump );
use Encode qw( encode );

my $lj_account_id = shift;
my $lj_entry_id = shift;
unless(defined $lj_account_id && defined $lj_entry_id)
{
  say STDERR "nx lj get account_id lj_entry_id";
  exit 2;
}

my $select = NX->nx_system_db->prepare(qq{
  SELECT
    a.name AS username,
    a.pass AS password,
    l.server AS server, 
    l.mode AS mode,
    l.name AS lj_short_name
  FROM 
    lj_accounts_shadow AS a JOIN 
    ljs AS l ON l.id = a.lj_id
  WHERE
    a.id = ?
});

$select->execute($lj_account_id);

my $client_args = $select->fetchrow_hashref;
unless(defined $client_args)
{
  say STDERR "invalid account_id ", $lj_account_id;
  exit 2;
}

my $client = new WebService::LiveJournal::Client(%$client_args);
say Dump($client->cachefriendgroups);
my $event = $client->getevent(itemid => $lj_entry_id);
die $WebService::LiveJournal::Client::error unless defined $event;
delete $event->{client};
say Dump($event);
