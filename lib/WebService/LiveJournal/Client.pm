package WebService::LiveJournal::Client;

use strict;
use warnings;
use v5.10;
use overload '""' => \&as_string;
use Digest::MD5 qw(md5_hex);
use RPC::XML;
use RPC::XML::Client;
use WebService::LiveJournal::FriendList;
use WebService::LiveJournal::FriendGroupList;
use WebService::LiveJournal::Event;
use WebService::LiveJournal::EventList;
use HTTP::Cookies;
use constant DEBUG => 0;

# ABSTRACT: Interface to the LiveJournal API
# VERSION

=head1 SYNOPSIS

new interface

 use WebService::LiveJournal;
 my $client = WebService::LiveJournal->new( username => 'foo', password => 'bar' );

same thing with the old interface

 use WebService::LiveJournal::Client;
 my $client = WebService::LiveJournal::Client->new( username => 'foo', password => 'bar' );
 die "connection error: $WebService::LiveJournal::Client::error" unless defined $client;

See L<WebService::LiveJournal::Event> for creating/updating LiveJournal events.

See L<WebService::LiveJournal::Friend> for making queries about friends.

See L<WebService::LiveJournal::FriendGroup> for getting your friend groups.

=head1 DESCRIPTION

This is a client class for communicating with LiveJournal using its API.  It is different
from the other LJ modules on CPAN in that it originally used the XML-RPC API.  It now
uses a hybrid of the flat and XML-RPC API to avoid bugs in some LiveJournal deployments.

There are two interfaces:

=over 4

=item L<WebService::LiveJournal>

The new interface, where methods throw an exception on error.

=item L<WebService::LiveJournal::Client>

The legacy interface, where methods return undef on error and
set $WebService::LiveJournal::Client::error

=back

It is recommended that for any new code that you use the new interface.

=cut

my $zero = new RPC::XML::int(0);
my $one = new RPC::XML::int(1);
our $lineendings_unix = new RPC::XML::string('unix');
my $challenge = new RPC::XML::string('challenge');
our $error;
our $error_request;

$RPC::XML::ENCODING = 'utf-8';  # uh... and WHY??? is this a global???

=head1 CONSTRUCTOR

=head2 WebService::LiveJournal::Client->new( %options )

Connects to a LiveJournal server using the host and user information
provided by C<%options>.

Signals an error depending on the interface
selected by throwing an exception or returning undef.

=head3 options

=over 4

=item server

The server hostname, defaults to www.livejournal.com

=item port

The server port, defaults to 80

=item username [required]

The username to login as

=item password [required]

The password to login with

=item mode

One of either C<cookie> or C<challenge>, defaults to C<cookie>.

=back

=cut

sub new    # arg: server, port, username, password, mode
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless {}, $class;
  
  my %arg = @_;
  
  my $server = $self->{server} = $arg{server} // 'www.livejournal.com';
  my $domain = $server;
  $domain =~ s/^([A-Za-z0-9]+)//;
  $self->{domain} = $domain;
  my $port = $self->{port} = $arg{port} || 80;
  $server .= ":$port" if $port != 80;
  my $client = $self->{client} = new RPC::XML::Client("http://$server/interface/xmlrpc");
  $self->{flat_url} = "http://$server/interface/flat";
  my $cookie_jar = $self->{cookie_jar} = new HTTP::Cookies;
  $client->useragent->cookie_jar($cookie_jar);
  $client->useragent->default_headers->push_header('X-LJ-Auth' => 'cookie');

  $self->{mode} = $arg{mode} // 'cookie';  # can be cookie or challenge

  my $username = $self->{username} = $arg{username};
  my $password = $arg{password};
  $self->{password} = $password if $self->{mode} ne 'cookie';
  
  $self->{auth} = [ ver => $one ];
  $self->{flat_auth} = [ ver => 1 ];
  
  if($self->{mode} eq 'cookie')
  {
  
    my $response = $self->send_request('getchallenge');
    return unless defined $response;
    my $auth_challenge = $response->value->{challenge};
    my $auth_response = md5_hex($auth_challenge, md5_hex($password));
  
    push @{ $self->{auth} }, username => new RPC::XML::string($username);
    push @{ $self->{flat_auth} }, user => $username;

    $response = $self->send_request('sessiongenerate',
            auth_method => $challenge,
            auth_challenge => new RPC::XML::string($auth_challenge),
            auth_response => new RPC::XML::string($auth_response),
    );

    return unless defined $response;

    my $ljsession = $self->{ljsession} = $response->value->{ljsession};
    $self->set_cookie(ljsession => $ljsession);  
    push @{ $self->{auth} }, auth_method => new RPC::XML::string('cookie');
    push @{ $self->{flat_auth} }, auth_method => 'cookie';
  
  }
  elsif($self->{mode} eq 'challenge')
  {
    push @{ $self->{auth} }, username => new RPC::XML::string($username);
    push @{ $self->{flat_auth} }, user => $username;
  }

  my $response = $self->send_request('login'
          #getmoods => $zero,
          #getmenus => $one,
          #getpickws => $one,
          #getpickwurls => $one,
  );
  
  return unless defined $response;
  
  my $h = $response->value;
  return $self->_set_error($h->{faultString}) if defined $h->{faultString};
  return $self->_set_error("unknown LJ error " . $h->{faultCode}->value) if defined $h->{faultCode};
  
  $self->{userid} = $h->{userid};
  $self->{fullname} = $h->{fullname};
  $self->{usejournals} = $h->{usejournals} || [];
  my $fastserver = $self->{fastserver} = $h->{fastserver};
  
  if($fastserver)
  {
    $self->set_cookie(ljfastserver => 1);
  }
  
  if($h->{friendgroups})
  {
    my $fg = $self->{cachefriendgroups} = new WebService::LiveJournal::FriendGroupList(response => $response);
  }
  
  $self->{message} = $h->{message};
  return $self;
}

=head1 ATTRIBUTES

These attributes are read-only.

=head2 server

The name of the LiveJournal server

=head2 port

The port used to connect to LiveJournal with

=head2 username

The username used to connect to LiveJournal

=head2 userid

The LiveJournal userid of the user used to connect to LiveJournal.
This is an integer.

=head2 fullname

The fullname of the user used to connect to LiveJournal as LiveJournal understands it

=head2 usejournals

List of shared/news/community journals that the user has permission to post in.

=head2 message

Message that should be displayed to the end user, if present.

=head2 useragent

Instance of L<LWP::UserAgent> used to connect to LiveJournal

=head2 cookie_jar

Instance of L<HTTP::Cookies> used to connect to LiveJournal with

=head2 fastserver

True if you have a paid account and are entitled to use the
fast server mode.

=cut

foreach my $name (qw( server username port userid fullname usejournals fastserver cachefriendgroups message cookie_jar ))
{
  eval qq{ sub $name { shift->{$name} } };
  die $@ if $@;
}

sub useragent { $_[0]->{client}->useragent }

=head1 METHODS

=head2 $client-E<gt>create_event( %options )

Creates a new event and returns it in the form of an instance of
L<WebService::LiveJournal::Event>.  This does not create the 
event on the LiveJournal server itself, until you use the 
C<update> methods on the event.

C<%options> contains a hash of attribute key, value pairs for
the new L<WebService::LiveJournal::Event>.  The only required
attributes are C<subject> and C<event>, though you may set these
values after the event is created as long as you set them
before you try to C<update> the event.  Thus this:

 my $event = $client->create(
   subject => 'a new title',
   event => 'some content',
 );
 $event->update;

is equivalent to this:

 my $event = $client->create;
 $event->subject('a new title');
 $event->event('some content');
 $event->update;

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=cut

sub create_event
{
  my $self = shift;
  my $event = new WebService::LiveJournal::Event(client => $self, @_);
  $event;
}

# legacy
sub create { shift->create_event(@_) }

=head2 $client-E<gt>get_events( $select_type, %query )

Selects events from the LiveJournal server.  The actual C<%query>
parameter requirements depend on the C<$select_type>.

Returns an instance of L<WebService::LiveJournal::EventList>.

Select types:

=over 4

=item syncitems

This query mode can be used to sync all entries with multiple calls.

=over 4

=item lastsync

The date of the last sync in the format of C<yyyy-mm-dd hh:mm:ss>

=back

=item day

This query can be used to fetch all the entries for a particular day.

=over 4

=item year

4 digit integer

=item month

1 or 2 digit integer, 1-31

=item day

integer 1-12 

=back

=item lastn

Fetch the last n events from the LiveJournal server.

=over 4

=item howmany

integer, default = 20, max = 50

=item beforedate

date of the format C<yyyy-mm-dd hh:mm:ss>

=back

=back

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=cut

sub get_events
{
  my $self = shift;
  my @list;
  my $selecttype = shift || 'lastn';
  push @list, selecttype => new RPC::XML::string($selecttype);

  my %arg = @_;

  if($selecttype eq 'syncitems')
  {
    push @list, lastsync => new RPC::XML::string($arg{lastsync}) if defined $arg{lastsync};
  }
  elsif($selecttype eq 'day')
  {
    unless(defined $arg{day} && defined $arg{month} && defined $arg{year})
    {
      return $self->_set_error('attempt to use selecttype=day without providing day!');
    }
    push  @list, 
      day   => new RPC::XML::int($arg{day}),
      month  => new RPC::XML::int($arg{month}),
      year  => new RPC::XML::int($arg{year});
  }
  elsif($selecttype eq 'lastn')
  {
    push @list, howmany => new RPC::XML::int($arg{howmany}) if defined $arg{howmany};
    push @list, howmany => new RPC::XML::int($arg{max}) if defined $arg{max};
    push @list, beforedate => new RPC::XML::string($arg{beforedate}) if defined $arg{beforedate};
  }
  elsif($selecttype eq 'one')
  {
    my $itemid = $arg{itemid} || -1;
    push @list, itemid => new RPC::XML::int($itemid);
  }
  else
  {
    return $self->_set_error("unknown selecttype: $selecttype");
  }
  
  push @list, truncate => new RPC::XML::int($arg{truncate}) if $arg{truncate};
  push @list, prefersubject => $one if $arg{prefersubject};
  push @list, lineendings => $lineendings_unix;
  push @list, usejournal => RPX::XML::string($arg{usejournal}) if $arg{usejournal};
  push @list, usejournal => RPX::XML::string($arg{journal}) if $arg{journal};

  my $response = $self->send_request('getevents', @list);
  return unless defined $response;
  if($selecttype eq 'one')
  {
    return new WebService::LiveJournal::Event(client => $self, %{ $response->value->{events}->[0] });
  }
  else
  {
    return new WebService::LiveJournal::EventList(client => $self, response => $response);
  }
}

# legacy
sub getevents { shift->get_events(@_) }

=head2 $client-E<gt>get_event( $itemid )

Given an C<itemid> (the internal LiveJournal identifier for an event).

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=cut

sub get_event
{
  my $self = shift;
  my %args = @_ == 1 ? (itemid => shift) : (@_);
  $self->get_events('one', %args);
}

# legacy
sub getevent { shift->get_event(@_) }

=head2 $client-E<gt>get_friends( %options )

Returns friend information associated with the account with which you are logged in.

=over 4

=item complete

If true returns your friends, stalkers (users who have you as a friend) and friend groups

 # $friends is a WS::LJ::FriendList containing your friends
 # $friend_of is a WS::LJ::FriendList containing your stalkers
 # $groups is a WS::LJ::FriendGroupList containing your friend groups
 my($friends, $friend_of, $groups) = $client-E<gt>get_friends( complete => 1 );

If false (the default) only your friends will be returned

 # $friends is a WS::LJ::FriendList containing your friends
 my $friends = $client-E<gt>get_friends;

=item friendlimit

If set to a numeric value greater than zero, this mode will only return the number of results indicated. 

=back

=cut

sub get_friends
{
  my $self = shift;
  my %arg = @_;
  my @list;
  push @list, friendlimit => new RPC::XML::int($arg{friendlimit}) if defined $arg{friendlimit};
  push @list, friendlimit => new RPC::XML::int($arg{limit}) if defined $arg{limit};
  push @list, includefriendof => 1, includegroups => 1 if $arg{complete};
  my $response = $self->send_request('getfriends', @list);
  return unless defined $response;
  if($arg{complete})
  {
    return (new WebService::LiveJournal::FriendList(response_list => $response->value->{friends}),
      new WebService::LiveJournal::FriendList(response_list => $response->value->{friendofs}),
      new WebService::LiveJournal::FriendGroupList(response => $response),
    );
  }
  else
  {
    return new WebService::LiveJournal::FriendList(response => $response);
  }
}

sub getfriends { shift->get_friends(@_) }

=head2 $client-E<gt>get_friend_of( %options )

Returns the list of users that are a friend of the logged in account.

Returns an instance of L<WebService::LiveJournal::FriendList>, a list of
L<WebService::LiveJournal::Friend>.

Options:

=over 4

=item friendoflimit

If set to a numeric value greater than zero, this mode will only return the number of results indicated

=back

=cut

sub get_friend_of
{
  my $self = shift;
  my %arg = @_;
  my @list;
  push @list, friendoflimit => new RPC::XML::int($arg{friendoflimit}) if defined $arg{friendoflimit};
  push @list, friendoflimit => new RPC::XML::int($arg{limit}) if defined $arg{limit};
  my $response = $self->send_request('friendof', @list);
  return unless defined $response;
  return new WebService::LiveJournal::FriendList(response => $response);
}

sub friendof { shift->get_friend_of(@_) }

=head2 $client-E<gt>get_friend_groups

Returns your friend groups.  This comes as an instance of
L<WebService::LiveJournal::FriendGroupList> that contains
zero or more instances of L<WebService::LiveJournal::FriendGroup>.

=cut

sub get_friend_groups
{
  my $self = shift;
  my $response = $self->send_request('getfriendgroups');
  return unless defined $response;
  return new WebService::LiveJournal::FriendGroupList(response => $response);
}

sub getfriendgroups { shift->get_friend_groups(@_) }

=head2 $client-E<gt>set_cookie( $key => $value )

This method allows you to set a cookie for the appropriate security and expiration information.
You shouldn't need to call it directly, but is available here if necessary.

=cut

sub set_cookie
{
  my $self = shift;
  my $key = shift;
  my $value = shift;

  $self->cookie_jar->set_cookie(
        0,                   # version
        $key => $value,      # key => value
        '/',                 # path
        $self->{domain},     # domain
        $self->port,         # port
        1,                   # path_spec
        0,                   # secure
        60*60*24,            # maxage
        0,                   # discard
  );
}

=head2 $client-E<gt>send_request( $procname, @arguments )

Make a low level request to LiveJournal with the given
C<$procname> (the rpc procedure name) and C<@arguments>
(should be L<RPC::XML> types).

On success returns the appropriate L<RPC::XML> type
(usually RPC::XML::struct).

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=cut

sub send_request
{
  my $self = shift;
  $self->_clear_error;
  my $count = $self->{count} || 1;
  my $procname = shift;
        
        #if(DEBUG)
        #{
        #  my %args = @_;
        #  %args = map { ($_ => $args{$_}->value) } keys %args;
        #  #say Dump({ request => { $procname => \%args } });
        #}
  
  my @challenge;
  if($self->{mode} eq 'challenge')
  {
    my $response = $self->{client}->send_request('LJ.XMLRPC.getchallenge');
    if(ref $response)
    {
      if($response->is_fault)
      {
        my $string = $response->value->{faultString};
        my $code = $response->value->{faultCode};
        $self->_set_error("$string ($code) on LJ.XMLRPC.getchallenge");
        return;
      }
      # else, stuff worked fall through 
    }
    else
    {
      if($count < 5 && $response =~ /HTTP server error: Method Not Allowed/i)
      {
        $self->{count} = $count+1;
        print STDERR "retry ($count)\n";
        sleep 10;
        my $response = $self->send_request($procname, @_);
        $self->{count} = $count;
        return $response;
      }
      return $self->_set_error($response);
    }

    # this is where we fall through down to from above
    my $auth_challenge = $response->value->{challenge};
    #print "challenge = $auth_challenge\n";
    my $auth_response = md5_hex($auth_challenge, md5_hex($self->{password}));
    @challenge = (
      auth_method => $challenge,
      auth_challenge => new RPC::XML::string($auth_challenge),
      auth_response => new RPC::XML::string($auth_response),
    );
    #print "challenge\n";
  }
  else
  {
    #print "cookie\n";
  }

  my $request = new RPC::XML::request(
      "LJ.XMLRPC.$procname",
      new RPC::XML::struct(
        @{ $self->{auth} },
        @challenge,
        @_,
      ),
  );


  my $response = $self->{client}->send_request($request);
  if(ref $response)
  {
                #if(DEBUG)
                #{
                #  say Dump({ response => $response->value });
                #}
    if($response->is_fault)
    {
      my $string = $response->value->{faultString};
      my $code = $response->value->{faultCode};
      $self->_set_error("$string ($code) on LJ.XMLRPC.$procname");
      $error_request = $request;
      return;
    }
    return $response;
  }
  else
  {
                #if(DEBUG)
                #{
                #  say Dump({ error => $response });
                #}
    if($count < 5 && $response =~ /HTTP server error: Method Not Allowed/i)
    {
      $self->{count} = $count+1;
      print STDERR "retry ($count)\n";
      sleep 10;
      my $response = $self->send_request($procname, @_);
      $self->{count} = $count;
      return $response;
    }
    return $self->_set_error($response);
  }
}

sub _post
{
  my $self = shift;
  my $ua = $self->{client}->useragent;
  my %arg = @_;
  #print "====\nOUT:\n";
  #foreach my $key (keys %arg)
  #{
  #  print "$key=$arg{$key}\n";
  #}
  my $http_response = $ua->post($self->{flat_url}, \@_);
  return $self->_set_error("HTTP Error: " . $http_response->status_line) unless $http_response->is_success;
  
  my $response_text = $http_response->content;
  my @list = split /\n/, $response_text;
  my %h;
  #print "====\nIN:\n";
  while(@list > 0)
  {
    my $key = shift @list;
    my $value = shift @list;
    #print "$key=$value\n";
    $h{$key} = $value;
  }
  
  return $self->_set_error("LJ Protocol error, server didn't return a success value") unless defined $h{success};
  return $self->_set_error("LJ Protocol error: $h{errmsg}") if $h{success} ne 'OK';
    
  return \%h;
}

sub as_string
{
  my $self = shift;
  my $username = $self->username;
  my $server = $self->server;
  "[ljclient $username\@$server]";
}

# TODO maybe test/doco

sub findallitemid
{
  my $self = shift;
  my %arg = @_;
  my $response = $self->send_request('syncitems');
  die $error unless defined $response;
  my $count = $response->value->{count};
  my $total = $response->value->{total};
  my $time;
  my @list;
  while(1)
  {
    #print "$count/$total\n";
    foreach my $item (@{ $response->value->{syncitems} })
    {
      $time = $item->{time};
      my $id = $item->{item};
      my $action = $item->{action};
      if($id =~ /^L-(\d+)$/)
      {
        push @list, $1;
      }
    }
    
    last if $count == $total;

    $response = $self->send_request('syncitems', lastsync => $time);
    die $error unless defined $response;
    $count = $response->value->{count};
    $total = $response->value->{total};
  }

  return @list;
}

=head2 $client-E<gt>send_flat_request( $procname, @arguments )

Sends a low level request to the LiveJournal server using the flat API,
with the given C<$procname> (the rpc procedure name) and C<@arguments>.

On success returns the appropriate response.

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=cut

sub send_flat_request
{
  my $self = shift;
  $self->_clear_error;
  my $count = $self->{count} || 1;
  my $procname = shift;
  my $ua = $self->{client}->useragent;

  my @challenge;
  if($self->{mode} eq 'challenge')
  {
    my $h = _post($self, mode => 'getchallenge');
    return unless defined $h;
    my %h = %{ $h };

    my $auth_challenge = $h{challenge};

    my $auth_response = md5_hex($auth_challenge, md5_hex($self->{password}));
    @challenge = (
      auth_method => 'challenge',
      auth_challenge => $auth_challenge,
      auth_response => $auth_response,
    );
  }
  
  return _post($self, 
    mode => $procname, 
    @{ $self->{flat_auth} },
    @challenge,
    @_
  );
}

sub _set_error
{
  my($self, $value) = @_;
  $error = $value;
  return;
}

sub _clear_error
{
  undef $error;
}

=head2 $client-E<gt>error

Returns the last error.  This just returns
$WebService::LiveJournal::Client::error, so it
is still a global, but is a slightly safer shortcut.

 my $event = $client->get_event($itemid) || die $client->error;

It is still better to use the newer interface which throws
an exception for any error.
 
=cut

sub error { $error }

1;

=head1 HISTORY

The code in this distribution was written many years ago to sync my website
with my LiveJournal.  It has some ugly warts and its interface was not well 
planned or thought out, it has many omissions and contains much that is apocryphal 
(or at least wildly inaccurate), but it (possibly) scores over the older 
LiveJournal modules on CPAN in that it has been used in production for 
many many years with very little maintenance required, and at the time of 
its original writing the documentation for those modules was sparse or misleading.

=head1 SEE ALSO

=over 4

=item

L<http://www.livejournal.com/doc/server/index.html>,

=item

L<Net::LiveJournal>,

=item

L<LJ::Simple>

=back

=cut
