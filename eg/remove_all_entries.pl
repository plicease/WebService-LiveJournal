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

my $count = 1;
while($count > 0)
{
  $count = 0;
  my $event_list = $client->getevents('lastn', howmany => 50);
  foreach my $event (@{ $event_list })
  {
    print $event->subject, "\n";
    $event->event('');	# setting the "event" or body to an entry to empty 
    $event->update;		# string will delete it
    $count++;
  }
}

print "$count entries deleted";
