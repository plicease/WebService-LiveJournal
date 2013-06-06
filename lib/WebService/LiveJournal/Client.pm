package WebService::LiveJournal::Client;

use strict;
use warnings;
use 5.012;
use overload '""' => \&toStr;
use Digest::MD5 qw(md5_hex);
use RPC::XML;
use RPC::XML::Client;
use WebService::LiveJournal::FriendList;
use WebService::LiveJournal::FriendGroupList;
use WebService::LiveJournal::Event;
use WebService::LiveJournal::EventList;
use HTTP::Cookies;
use YAML::XS qw( Dump );
use constant DEBUG => 0;

# ABSTRACT: Interface to the LiveJournal API
# VERSION

=head1 SYNOPSIS

 use WebService::LiveJournal::Client;
 
 my $client = WebService::LiveJournal::Client->new( username => 'foo', password => 'bar' );
 die "connection error: $WebService::LiveJournal::Client::error" unless defined $client;

=head1 DESCRIPTION

This is the client class for communicating with LiveJournal using its API.  It mostly
uses the XML-RPC version of the API, but it can be configured to use the flat API
in some circumstances to work around bugs in some LiveJournal servers.

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
provided by C<%options>.  Returns an instance of 
WebService::LiveJournal::Client on success, returns undef and sets
$WebService::LiveJournal::Client::error to an appropriate message
on failure.

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

One of eitehr C<cookie> or C<challenge>, defaults to C<cookie>.

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
    return undef unless defined $response;
    my $auth_challenge = $response->value->{challenge};
    my $auth_response = md5_hex($auth_challenge, md5_hex($password));
  
    push @{ $self->{auth} }, username => new RPC::XML::string($username);
    push @{ $self->{flat_auth} }, user => $username;

    $response = $self->send_request('sessiongenerate',
            auth_method => $challenge,
            auth_challenge => new RPC::XML::string($auth_challenge),
            auth_response => new RPC::XML::string($auth_response),
    );

    return undef unless defined $response;

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
  
  return undef unless defined $response;
  
  my $h = $response->value;
  if(defined $h->{faultString})
  {
    $error = $h->{faultString};
    return undef;
  }
  if(defined $h->{faultCode})
  {
    $error = "unknown LJ error " . $h->{faultCode}->value;
    return undef;
  }
  
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

=head2 $client-E<gt>server

The name of the LiveJournal server

=head2 $client-E<gt>port

The port used to connect to LiveJournal with

=head2 $client-E<gt>username

The username used to connect to LiveJournal

=head2 $client-E<gt>userid

The LiveJournal userid of the user used to connect to LiveJournal.
This is an integer.

=head2 $client-<gt>fullname

The fullname of the user used to connect to LiveJournal as LiveJournal understands it

=head2 $client-E<gt>usejournals

FIXME document

=head2 $client-E<gt>message

FIXME document

=head2 $client-E<gt>useragent

Instance of L<LWP::UserAgent> used to connect to LiveJournal

=head2 $client-E<gt>cookie_jar

Instance of L<HTTP::Cookies> used to connect to LiveJournal with

=head2 $client-E<gt>usejournals

FIXME document

=cut

sub server { $_[0]->{server} }
sub username { $_[0]->{username} }
sub port { $_[0]->{port} }
sub userid { $_[0]->{userid} }
sub fullname { $_[0]->{fullname} }
sub usejournals { @{ $_[0]->{usejournals} } }
sub fastserver { $_[0]->{fastserver} }
sub cachefriendgroups { $_[0]->{cachefriendgroups} }
sub message { $_[0]->{message} }
sub useragent { $_[0]->{client}->useragent }
sub cookie_jar { $_[0]->{cookie_jar} }

sub set_cookie
{
  my $self = shift;
  my $key = shift;
  my $value = shift;

  $self->cookie_jar->set_cookie(
        0,         # version
        $key => $value,      # key => value
        '/',        # path
        $self->{domain},    # domain
        $self->port,       # port
        1,         # path_spec
        0,        # secure
        60*60*24,      # maxage
        0,        # discard
  );
}

sub send_request
{
  $error = undef;
  my $self = shift;
  my $count = $self->{count} || 1;
  my $procname = shift;
        
        if(DEBUG)
        {
          my %args = @_;
          %args = map { ($_ => $args{$_}->value) } keys %args;
          say Dump({ request => { $procname => \%args } });
        }
  
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
        $error = "$string ($code) on LJ.XMLRPC.getchallenge";
        return undef;
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
      $error = $response;
      return undef;
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
                if(DEBUG)
                {
                  say Dump({ response => $response->value });
                }
    if($response->is_fault)
    {
      my $string = $response->value->{faultString};
      my $code = $response->value->{faultCode};
      $error = "$string ($code) on LJ.XMLRPC.$procname";
      $error_request = $request;
      return undef;
    }
    return $response;
  }
  else
  {
                if(DEBUG)
                {
                  say Dump({ error => $response });
                }
    if($count < 5 && $response =~ /HTTP server error: Method Not Allowed/i)
    {
      $self->{count} = $count+1;
      print STDERR "retry ($count)\n";
      sleep 10;
      my $response = $self->send_request($procname, @_);
      $self->{count} = $count;
      return $response;
    }
    $error = $response;
    return undef;
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
  unless($http_response->is_success)
  {
    $error = "HTTP Error: " . $http_response->status_line;
    return undef;
  }
  
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
  
  unless(defined $h{success})
  {
    $error = "LJ Protocol error, server didn't return a success value";
    return undef;
  }
    
  if($h{success} ne 'OK')
  {
    $error = "LJ Protocol error: $h{errmsg}";
    return undef;
  }
  
  return \%h;
}

sub send_flat_request
{
  $error = undef;
  my $self = shift;
  my $count = $self->{count} || 1;
  my $procname = shift;
  my $ua = $self->{client}->useragent;

  my @challenge;
  if($self->{mode} eq 'challenge')
  {
    my $h = _post($self, mode => 'getchallenge');
    return undef unless defined $h;
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

sub friendof
{
  my $self = shift;
  my %arg = @_;
  my @list;
  push @list, friendoflimit => new RPC::XML::int($arg{friendoflimit}) if defined $arg{friendoflimit};
  push @list, friendoflimit => new RPC::XML::int($arg{limit}) if defined $arg{limit};
  my $response = $self->send_request('friendof', @list);
  return undef unless defined $response;
  return new WebService::LiveJournal::FriendList(response => $response);
}

sub getfriends
{
  my $self = shift;
  my %arg = @_;
  my @list;
  push @list, friendlimit => new RPC::XML::int($arg{friendlimit}) if defined $arg{friendlimit};
  push @list, friendlimit => new RPC::XML::int($arg{limit}) if defined $arg{limit};
  push @list, includefriendof => 1, includegroups => 1 if $arg{complete};
  my $response = $self->send_request('getfriends', @list);
  return undef unless defined $response;
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

sub getfriendgroups
{
  my $self = shift;
  my $response = $self->send_request('getfriendgroups');
  return undef unless defined $response;
  return new WebService::LiveJournal::FriendGroupList(response => $response);
}

# truncate    (int)
# prefersubject    (bool)
# noprop    (bool)
# lineendings (req)  (string)
# usejournal    (string)

# selecttype (req)  day|lastn|one|syncitems
#  selecttype=syncitems
#   lastsync    (string-date yyyy-mm-dd hh:mm:ss) (for selecttype=syncitems)
#  selecttype=day
#   year    (4-digit int) (for selecttype=day)
#   month    (1- or 2-digit int) (for selecttype=day)
#   day      (1- or 2-digit day of the month)
#  selecttype=lastn
#   howmany    (int, default=20, max=50)
#   beforedate    (string-date yyyy-mm-dd hh:mm:ss)
#  selecttype=one
#   itemid    (int) -1 for last entry

sub getevents
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
      $error = 'attempt to use selecttype=day without providing day!';
      return undef;
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
    $error = "unknown selecttype: $selecttype";
    return undef;
  }
  
  push @list, truncate => new RPC::XML::int($arg{truncate}) if $arg{truncate};
  push @list, prefersubject => $one if $arg{prefersubject};
  push @list, lineendings => $lineendings_unix;
  push @list, usejournal => RPX::XML::string($arg{usejournal}) if $arg{usejournal};
  push @list, usejournal => RPX::XML::string($arg{journal}) if $arg{journal};

  my $response = $self->send_request('getevents', @list);
  return undef unless defined $response;
  if($selecttype eq 'one')
  {
    return new WebService::LiveJournal::Event(client => $self, %{ $response->value->{events}->[0] });
  }
  else
  {
    return new WebService::LiveJournal::EventList(client => $self, response => $response);
  }
}

sub getevent { my $self = shift; $self->getevents('one', @_) }

sub create
{
  my $self = shift;
  my $event = new WebService::LiveJournal::Event(client => $self, @_);
  $event;
}

sub toStr
{
  my $self = shift;
  my $username = $self->username;
  my $server = $self->server;
  "[ljclient $username\@$server]";
}

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

1;

=head1 SEE ALSO

L<WebService::LiveJournal>

=cut
