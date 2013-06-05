use strict;
use NX;
use WebService::LiveJournal::Client;

print "pass: ";
my $password = <STDIN>;
chomp($password);

my $client = new WebService::LiveJournal::Client(
	server => 'www.greatestjournal.com',
	username => 'plicease',
	password => $password,
);

unless(defined $client)
{
	print "connect error: $WebService::LiveJournal::Client::error\n";
	exit;
}

print "$client\n";

if($client->fastserver)
{
	print "fast server\n";
}
else
{
	print "slow server\n";
}


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
