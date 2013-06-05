use strict;
use warnings;
use 5.012;
use autodie;
use NX;
use WebService::LiveJournal::Client;
use YAML qw( Dump );
use Encode qw( encode );

my $lj_account_id = shift;
unless(defined $lj_account_id)
{
  say STDERR "nx lj backup account_id";
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

open(OUT, sprintf(">%s.%s.yml", $client_args->{username}, $client_args->{lj_short_name}));
binmode OUT, ":raw";

print OUT Dump([ map { { id => $_->id, name => $_->name} } @{ $client->cachefriendgroups } ]);

my @ids = $client->findallitemid;

while(my $id = shift @ids)
{
  my $event = $client->getevent(itemid => $id); 
  
  unless(defined $event)
  {
    sleep 5;
    $event = $client->getevent(itemid => $id);
  }

  unless(defined $event)
  {
    sleep 15;
    $event = $client->getevent(itemid => $id);
  }
  
  unless(defined $event)
  {
    sleep 30;
    $event = $client->getevent(itemid => $id);
  }
  
  unless(defined $event)
  {
    say STDERR "failed getting event with id = $id after 4 tries!";
    exit 2;
  }
  
  my $html_id;
  $html_id = $1 
    if $event->url =~ m!/(\d+).html$!;
  die "could not determine html id!"
    unless defined $html_id;

  my $access_type = $event->security;
  if(defined $event->allowmask)
  {
    given($event->allowmask)
    {
      when(1) { $access_type = 'friends' }
      when(8) { $access_type = 'private' }
      when(128) { $access_type = 'grayka' }
      default { die "unknown allowmask: ", $event->allowmask }
    }
  }

  my $h = {
    lj_entry => {
      anum => $event->anum,
      html_id => $html_id,
      item_id => $event->itemid,
    },
    time => {
      day => $event->day,
      hour => $event->hour,
      min => $event->min,
      year => $event->year,    
      month => $event->month,
    },
    msg => $event->event,
    title => $event->subject,
    access => {
      security => $event->security,
      allowmask => $event->allowmask,
    },
    access_type => $access_type,
    props => $event->props,
    url => $event->url,
  };
  
  print OUT Dump($h);
}

close OUT;
