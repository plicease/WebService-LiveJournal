use strict;
use warnings;
use Test::More;
use WebService::LiveJournal;

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
plan tests => 5;

my($user,$pass,$server) = split /:/, $ENV{TEST_WEBSERVICE_LIVEJOURNAL};

my $client = WebService::LiveJournal->new(
  server => $server,
  username => $user,
  password => $pass,
);

my $list = $client->get_friend_of;
isa_ok $list, 'WebService::LiveJournal::FriendList';

my($me)       = grep { $_->username eq $user } @$list;
my($plicease) = grep { $_->username eq 'plicease' } @$list;
isa_ok $me, 'WebService::LiveJournal::Friend';
isa_ok $plicease, 'WebService::LiveJournal::Friend';

is $me->username, $user, "me.username = $user";
is $plicease->username, 'plicease', 'plicease.username = plicease';