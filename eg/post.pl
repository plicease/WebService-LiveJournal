use strict;
use warnings;
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

print "subject: ";
my $subject = <STDIN>;
chomp $subject;

print "content: (^D or EOF when done)\n";
my @lines = <STDIN>;
chomp @lines;

my $event = $client->create(
  subject => $subject,
  event => join("\n", @lines),
);

if($event->update)
{
  print "posted $event with $client\n";
  print "itemid = ", $event->itemid, "\n";
  print "url    = ", $event->url, "\n";
  print "anum   = ", $event->anum, "\n";
}
else
{
  die $WebService::LiveJournal::Client::error;
}
