use WebService::LiveJournal::FOAF;

foreach my $username (qw/ plicease princeofsocks a_eliseev /)
{
	my $user = new WebService::LiveJournal::FOAF(
		server => 'www.livejournal.com',
		user => $username,
	);
	print "$username\n";
	$user->save;
	$user->save_friends;
}
