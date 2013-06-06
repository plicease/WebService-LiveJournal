use strict;
use warnings;
use WebService::LiveJournal::Client;

print "WARNING WARNING WARNING\n";
print "this will remove all entries in your LiveJournal account\n";
print "this probably cannot be undone\n";
print "WARNING WARNING WARNING\n";

print "user: ";
my $user = <STDIN>;
chomp $user;
print "pass: ";
my $password = <STDIN>;
chomp $password;

my $client = WebService::LiveJournal::Client->new(
  server => 'www.livejournal.com',
  username => $user,
  password => $password,
);

unless(defined $client)
{
  print "connect error: $WebService::LiveJournal::Client::error\n";
  exit;
}

print "$client\n";

my $count = 0;
while(1)
{
  my $event_list = $client->getevents('lastn', howmany => 50);
  last unless @{ $event_list } > 0;
  foreach my $event (@{ $event_list })
  {
    print $event->subject, "\n";
    $event->delete;
    $count++;
  }
}

print "$count entries deleted\n";
