use strict;
use warnings;
use Test::More;
use WebService::LiveJournal;

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
plan tests => 3;

my($user,$pass,$server) = split /:/, $ENV{TEST_WEBSERVICE_LIVEJOURNAL};

my $client = WebService::LiveJournal->new(
  server => $server,
  username => $user,
  password => $pass,
);

my $response1 = $client->console_command('print', 'hello world', '!error', 'and again');

is $response1->[1]->[1], 'hello world';
is $response1->[2]->[1], '!error';
is $response1->[3]->[1], 'and again';

#use YAML ();
#note YAML::Dump($response1);
