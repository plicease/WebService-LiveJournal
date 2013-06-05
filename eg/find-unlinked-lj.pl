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

my @list= $client->findallitemid;
unless(defined @list)
{
	print "syncitems error: $WebService::LiveJournal::Client::error\n";
	exit;
}

my $dbh = NX::ConnectDB();
my $sth = $dbh->prepare(join(' ', qw/
		SELECT
			lje.id AS id
		FROM
			lj_entries AS lje,
			blog_entries AS b
		WHERE
			item_id = ? AND
			lje.blog_entry_id = b.id AND
			b.journal_id = 1 AND
			lj_id = 1
/));

my @known = qw/

964 957 940 929 930 912 672 676 671 76 338 342 349 354 350 355 356 359 367 403

/;

my %known;
foreach my $known (@known) { $known{$known} = 1 }

open(OUT, ">unlinked.html") || die "unable to write to unlinked.html $!";
print OUT "<html><heaed><title>unlinked</title></head><body><ul>\n";

foreach my $itemid (@list)
{
	next if $known{$itemid};
	$sth->execute($itemid);
	next if $sth->rows > 0;
	my $event = $client->getevent(itemid => $itemid);
	unless(defined $event)
	{
		print "fetch error: $WebService::LiveJournal::Client::error\n";
		exit;
	}
	my $url = $event->url;
	my $title = $event->subject;
	$title = 'untitled' if $title eq '';
	print "$event\n";
	print "$url\n";
	
	my $anum = $event->anum;
	my $htmlid = $event->htmlid;
	
	my $year = $event->year;
	my $month = sprintf("%d", $event->month);
	my $day = sprintf("%d", $event->day);
	my $guess = "http://www.wdlabs.com/twilight/temporal/$year/$month/$day";
	
	print OUT "<li><a href=\"$url\">$title</a> [$itemid $anum $htmlid] ";
	print OUT "<a href=\"$guess\">guess</a>";
	print OUT "</li>\n";
}

print OUT "</ul></body></html>\n";
