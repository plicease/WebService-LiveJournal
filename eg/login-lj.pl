use strict;
use NX;
use WebService::LiveJournal::Client;

print "pass: ";
my $password = <STDIN>;
chomp($password);

my $client = new WebService::LiveJournal::Client(
	server => 'www.livejournal.com',
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
