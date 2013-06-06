use strict;
use warnings;
use Test::More;
use WebService::LiveJournal::Client;

# setenv TEST_WEBSERVICE_LIVEJOURNAL "foodaddyz2:jgdfksLg42mxc:www.livejournal.com"

if(defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL})
{
  plan tests => 10;
}
else
{
  plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL';
}

my($user,$pass,$server) = split /:/, $ENV{TEST_WEBSERVICE_LIVEJOURNAL};

my $client = WebService::LiveJournal::Client->new(
  server => $server,
  username => $user,
  password => $pass,
);

diag $WebService::LiveJournal::Client::error unless defined $client;

isa_ok $client, 'WebService::LiveJournal::Client';

SKIP: {
  skip 'excessive tests for bad username/password gets us banned', 2;
  is(WebService::LiveJournal::Client->new( server => $server, username => $user, password => 'bogus' ), undef, 'bad password new returns undef');
  is $WebService::LiveJournal::Client::error, 'Invalid password (101) on LJ.XMLRPC.sessiongenerate', '$error set';
};

is eval { $client->server },   $server, "client.server = $server";
is eval { $client->username }, $user, "client.username = $user";
is eval { $client->port },     80, 'client.port = 80';

like eval { $client->userid }, qr{^\d+$}, "client.userid = " . eval { $client->userid };
ok( eval { defined($client->fullname) && $client->fullname ne '' }, "client.fullname = " . eval { $client->fullname });

diag 'client.usejournals = ' . ($client->usejournals // 'undef');
diag 'client.fastserver  = ' . ($client->fastserver // 'undef');
diag 'client.message     = ' . ($client->message // 'undef');

isa_ok $client->useragent, 'LWP::UserAgent';
isa_ok $client->cookie_jar, 'HTTP::Cookies';
