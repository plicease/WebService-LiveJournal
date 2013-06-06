use strict;
use WebService::LiveJournal::Client;

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

if($client->fastserver)
{
	print "fast server\n";
}
else
{
        print "value = ", $client->fastserver, "\n";
	print "slow server\n";
}
