use strict;
use warnings;
use Test::More;
use WebService::LiveJournal;
use Time::HiRes qw( sleep );

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
plan tests => 1;

my($user,$pass,$server) = split /:/, $ENV{TEST_WEBSERVICE_LIVEJOURNAL};

my $client = WebService::LiveJournal::Client->new(
  server => $server,
  username => $user,
  password => $pass,
);

diag $WebService::LiveJournal::Client::error unless defined $client;

while(1)
{
  my $list = $client->getevents('lastn', howmany => 50);
  last unless @$list > 0;
  foreach my $event (@$list)
  {
    note "deleting $event";
    $event->delete;
  }
}

foreach my $num (1..67)
{
  my $event = $client->create(
    subject  => "title $num",
    event    => "bar\nbaz\n",
    year     => 1969+$num,
    month    => 6,
    day      => 29,
    hour     => 4,
    min      => 30,
    security => 'public',
  );
  $event->save;
  note "created $num";
  sleep 0.05;
}

pass 'okay';
