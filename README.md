# WebService::LiveJournal [![Build Status](https://travis-ci.org/plicease/WebService-LiveJournal.svg)](http://travis-ci.org/plicease/WebService-LiveJournal)

Interface to the LiveJournal API

# SYNOPSIS

new interface

```perl
use WebService::LiveJournal;
my $client = WebService::LiveJournal->new( username => 'foo', password => 'bar' );
```

same thing with the old interface

```perl
use WebService::LiveJournal::Client;
my $client = WebService::LiveJournal::Client->new( username => 'foo', password => 'bar' );
die "connection error: $WebService::LiveJournal::Client::error" unless defined $client;
```

See [WebService::LiveJournal::Event](https://metacpan.org/pod/WebService::LiveJournal::Event) for creating/updating LiveJournal events.

See [WebService::LiveJournal::Friend](https://metacpan.org/pod/WebService::LiveJournal::Friend) for making queries about friends.

See [WebService::LiveJournal::FriendGroup](https://metacpan.org/pod/WebService::LiveJournal::FriendGroup) for getting your friend groups.

# DESCRIPTION

This is a client class for communicating with LiveJournal using its API.  It is different
from the other LJ modules on CPAN in that it originally used the XML-RPC API.  It now
uses a hybrid of the flat and XML-RPC API to avoid bugs in some LiveJournal deployments.

There are two interfaces:

- [WebService::LiveJournal](https://metacpan.org/pod/WebService::LiveJournal)

    The new interface, where methods throw an exception on error.

- [WebService::LiveJournal::Client](https://metacpan.org/pod/WebService::LiveJournal::Client)

    The legacy interface, where methods return undef on error and
    set $WebService::LiveJournal::Client::error

It is recommended that for any new code that you use the new interface.

# CONSTRUCTOR

## new

```perl
my $client = WebService::LiveJournal::Client->new( %options )
```

Connects to a LiveJournal server using the host and user information
provided by `%options`.

Signals an error depending on the interface
selected by throwing an exception or returning undef.

### options

- server

    The server hostname, defaults to www.livejournal.com

- port

    The server port, defaults to 80

- username \[required\]

    The username to login as

- password \[required\]

    The password to login with

- mode

    One of either `cookie` or `challenge`, defaults to `cookie`.

# ATTRIBUTES

These attributes are read-only.

## server

The name of the LiveJournal server

## port

The port used to connect to LiveJournal with

## username

The username used to connect to LiveJournal

## userid

The LiveJournal userid of the user used to connect to LiveJournal.
This is an integer.

## fullname

The fullname of the user used to connect to LiveJournal as LiveJournal understands it

## usejournals

List of shared/news/community journals that the user has permission to post in.

## message

Message that should be displayed to the end user, if present.

## useragent

Instance of [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) used to connect to LiveJournal

## cookie\_jar

Instance of [HTTP::Cookies](https://metacpan.org/pod/HTTP::Cookies) used to connect to LiveJournal with

## fastserver

True if you have a paid account and are entitled to use the
fast server mode.

# METHODS

## create\_event

```
$client->create_event( %options )
```

Creates a new event and returns it in the form of an instance of
[WebService::LiveJournal::Event](https://metacpan.org/pod/WebService::LiveJournal::Event).  This does not create the 
event on the LiveJournal server itself, until you use the 
`update` methods on the event.

`%options` contains a hash of attribute key, value pairs for
the new [WebService::LiveJournal::Event](https://metacpan.org/pod/WebService::LiveJournal::Event).  The only required
attributes are `subject` and `event`, though you may set these
values after the event is created as long as you set them
before you try to `update` the event.  Thus this:

```perl
my $event = $client->create(
  subject => 'a new title',
  event => 'some content',
);
$event->update;
```

is equivalent to this:

```perl
my $event = $client->create;
$event->subject('a new title');
$event->event('some content');
$event->update;
```

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

## get\_events

```
$client->get_events( $select_type, %query )
```

Selects events from the LiveJournal server.  The actual `%query`
parameter requirements depend on the `$select_type`.

Returns an instance of [WebService::LiveJournal::EventList](https://metacpan.org/pod/WebService::LiveJournal::EventList).

Select types:

- syncitems

    This query mode can be used to sync all entries with multiple calls.

    - lastsync

        The date of the last sync in the format of `yyyy-mm-dd hh:mm:ss`

- day

    This query can be used to fetch all the entries for a particular day.

    - year

        4 digit integer

    - month

        1 or 2 digit integer, 1-31

    - day

        integer 1-12 

- lastn

    Fetch the last n events from the LiveJournal server.

    - howmany

        integer, default = 20, max = 50

    - beforedate

        date of the format `yyyy-mm-dd hh:mm:ss`

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

## get\_event

```
$client->get_event( $itemid )
```

Given an `itemid` (the internal LiveJournal identifier for an event).

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

## sync\_items

```perl
$client->sync_items( $cb )
$client->sync_items( last_sync => $time, $cb )
```

Fetch all of the items which have been created/modified since the last sync.
If `last_sync => $time` is not provided then it will fetch all events.
For each item that has been changed it will call the code reference `$cb`
with three arguments:

```
$cb->($action, $type, $id)
```

- action

    One of `create` or `update`

- type

    For "events" (journal entries) this is `L`

- id

    The internal LiveJournal server id for the item.  An integer.
    For events, the actual event can be fetched using the `get_event`
    method.

If the callback throws an exception, then no more entries will be processed.
If the callback does not throw an exception, then the next item will be
processed.

This method returns the time of the last entry successfully processed, which
can be passed into `sync_item` the next time to only get the items that have
changed since the first time.

Here is a broad example:

```perl
# first time:
my $time = $client->sync_items(sub {
  my($action, $type, $id) = @_;
  if($type eq 'L')
  {
    my $event = $client->get_item($id);
    # ...
    if(error condition)
    {
      die 'error happened';
    }
  }
});

# if an error happened during the sync
my $error = $client->error;

# next time:
$time = $client->sync_items(last_sync => $time, sub {
  ...
});
```

Because the `syncitems` rpc that this method depends on
can make several requests before it completes it can fail
half way through.  If this happens, you can restart where
the last successful item was processed by passing the
return value back into `sync_items` again.  You can tell
that `sync_item` completed without error because the 
`$client->error` accessor should return a false value.

## get\_friends

```
$client->get_friends( %options )
```

Returns friend information associated with the account with which you are logged in.

- complete

    If true returns your friends, stalkers (users who have you as a friend) and friend groups

    ```perl
    # $friends is a WS::LJ::FriendList containing your friends
    # $friend_of is a WS::LJ::FriendList containing your stalkers
    # $groups is a WS::LJ::FriendGroupList containing your friend groups
    my($friends, $friend_of, $groups) = $client-E<gt>get_friends( complete => 1 );
    ```

    If false (the default) only your friends will be returned

    ```perl
    # $friends is a WS::LJ::FriendList containing your friends
    my $friends = $client-E<gt>get_friends;
    ```

- friendlimit

    If set to a numeric value greater than zero, this mode will only return the number of results indicated. 

## get\_friends\_of

```
$client->get_friend_of( %options )
```

Returns the list of users that are a friend of the logged in account.

Returns an instance of [WebService::LiveJournal::FriendList](https://metacpan.org/pod/WebService::LiveJournal::FriendList), a list of
[WebService::LiveJournal::Friend](https://metacpan.org/pod/WebService::LiveJournal::Friend).

Options:

- friendoflimit

    If set to a numeric value greater than zero, this mode will only return the number of results indicated

## get\_friend\_groups

```
$client->get_friend_groups
```

Returns your friend groups.  This comes as an instance of
[WebService::LiveJournal::FriendGroupList](https://metacpan.org/pod/WebService::LiveJournal::FriendGroupList) that contains
zero or more instances of [WebService::LiveJournal::FriendGroup](https://metacpan.org/pod/WebService::LiveJournal::FriendGroup).

## get\_user\_tags

```perl
$client->get_user_tags;
$client->get_user_tags( $journal_name );
```

Fetch the tags associated with the given journal, or the users journal
if not specified.  This method returns a list of zero or more
[WebService::LiveJournal::Tag](https://metacpan.org/pod/WebService::LiveJournal::Tag) objects.

## console\_command

```
$client->console_command( $command, @arguments )
```

Execute the given console command with the given arguments on the
LiveJournal server.  Returns the output as a list reference.
Each element in the list represents a line out output and consists
of a list reference containing the type of output and the text
of the output.  For example:

```perl
my $ret = $client->console_command( 'print', 'hello world' );
```

returns:

```
[
  [ 'info',    "Welcome to 'print'!" ],
  [ 'success', "hello world" ],
]
```

## batch\_console\_commands

```
$client->batch_console_commands( $command1, $callback);
$client->batch_console_commands( $command1, $callback, [ $command2, $callback, [ ... ] );
```

Execute a list of commands on the LiveJournal server in one request. Each command is a list reference. Each callback 
associated with each command will be called with the results of that command (in the same format returned by 
`console_command` mentioned above, except it is passed in as a list instead of a list reference).  Example:

```perl
$client->batch_console_commands(
  [ 'print', 'something to print' ],
  sub {
    my @output = @_;
    ...
  },
  [ 'print', 'something else to print' ],
  sub {
    my @output = @_;
    ...
  },
);
```

## set\_cookie

```perl
$client->set_cookie( $key => $value )
```

This method allows you to set a cookie for the appropriate security and expiration information.
You shouldn't need to call it directly, but is available here if necessary.

## send\_request

```
$client->send_request( $procname, @arguments )
```

Make a low level request to LiveJournal with the given
`$procname` (the rpc procedure name) and `@arguments`
(should be [RPC::XML](https://metacpan.org/pod/RPC::XML) types).

On success returns the appropriate [RPC::XML](https://metacpan.org/pod/RPC::XML) type
(usually RPC::XML::struct).

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

## send\_flat\_request

```
$client->send_flat_request( $procname, @arguments )
```

Sends a low level request to the LiveJournal server using the flat API,
with the given `$procname` (the rpc procedure name) and `@arguments`.

On success returns the appropriate response.

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

## error

```
$client->error
```

Returns the last error.  This just returns
$WebService::LiveJournal::Client::error, so it
is still a global, but is a slightly safer shortcut.

```perl
my $event = $client->get_event($itemid) || die $client->error;
```

It is still better to use the newer interface which throws
an exception for any error.

# EXAMPLES

These examples are included with the distribution in its 'example' directory.

Here is a simple example of how you would login/authenticate with a 
LiveJournal server:

```perl
use strict;
use warnings;
use WebService::LiveJournal;

print "user: ";
my $user = <STDIN>;
chomp $user;
print "pass: ";
my $password = <STDIN>;
chomp $password;

my $client = WebService::LiveJournal->new(
  server => 'www.livejournal.com',
  username => $user,
  password => $password,
);

print "$client\n";

if($client->fastserver)
{
  print "fast server\n";
}
else
{
  print "slow server\n";
}
```

Here is a simple example showing how you can post an entry to your 
LiveJournal:

```perl
use strict;
use warnings;
use WebService::LiveJournal;

print "user: ";
my $user = <STDIN>;
chomp $user;
print "pass: ";
my $password = <STDIN>;
chomp $password;

my $client = WebService::LiveJournal->new(
  server => 'www.livejournal.com',
  username => $user,
  password => $password,
);

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

$event->update;

print "posted $event with $client\n";
print "itemid = ", $event->itemid, "\n";
print "url    = ", $event->url, "\n";
print "anum   = ", $event->anum, "\n";
```

Here is an example of a script that will remove all entries from a 
LiveJournal.  Be very cautious before using this script, once the 
entries are removed they cannot be brought back from the dead:

```perl
use strict;
use warnings;
use WebService::LiveJournal;

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

my $client = WebService::LiveJournal->new(
  server => 'www.livejournal.com',
  username => $user,
  password => $password,
);

print "$client\n";

my $count = 0;
while(1)
{
  my $event_list = $client->get_events('lastn', howmany => 50);
  last unless @{ $event_list } > 0;
  foreach my $event (@{ $event_list })
  {
    print "rm: ", $event->subject, "\n";
    $event->delete;
    $count++;
  }
}

print "$count entries deleted\n";
```

Here is a really simple command line interface to the LiveJournal
admin console.  Obvious improvements like better parsing of the commands
and not displaying the password are left as an exercise to the reader.

```perl
use strict;
use warnings;
use WebService::LiveJournal;

my $client = WebService::LiveJournal->new(
  server => 'www.livejournal.com',
  username => do {
    print "user: ";
    my $user = <STDIN>;
    chomp $user;
    $user;
  },
  password => do {
    print "pass: ";
    my $pass = <STDIN>;
    chomp $pass;
    $pass;
  },
);

while(1)
{
  print "> ";
  my $command = <STDIN>;
  unless(defined $command)
  {
    print "\n";
    last;
  }
  chomp $command;
  $client->batch_console_commands(
    [ split /\s+/, $command ],
    sub {
      foreach my $line (@_)
      {
        my($type, $text) = @$line;
        printf "%8s : %s\n", $type, $text;
      }
    }
  );
}
```

# HISTORY

The code in this distribution was written many years ago to sync my website
with my LiveJournal.  It has some ugly warts and its interface was not well 
planned or thought out, it has many omissions and contains much that is apocryphal 
(or at least wildly inaccurate), but it (possibly) scores over the older 
LiveJournal modules on CPAN in that it has been used in production for 
many many years with very little maintenance required, and at the time of 
its original writing the documentation for those modules was sparse or misleading.

# SEE ALSO

- [http://www.livejournal.com/doc/server/index.html](http://www.livejournal.com/doc/server/index.html),
- [Net::LiveJournal](https://metacpan.org/pod/Net::LiveJournal),
- [LJ::Simple](https://metacpan.org/pod/LJ::Simple)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
