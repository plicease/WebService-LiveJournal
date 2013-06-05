use strict;
use NX;
use NX::AskPassword qw/ postgres_askpassword /;

my $dbh = NX::ConnectDB(ask_pass => \&postgres_askpassword);

my $sql = qq/

SELECT
	be.id AS id,
	be.title AS title
FROM
	blog_entries AS be
	JOIN lj_entries AS le ON be.id = le.blog_entry_id
	JOIN journals AS j ON be.journal_id = j.id
	JOIN ljs ON ljs.id = le.lj_id
WHERE
	j.name = 'twilight' AND
	ljs.name = 'lj'
ORDER BY
	be.time

/;

my $fetch = $dbh->prepare($sql);
$fetch->execute;

my $insert = $dbh->prepare("INSERT INTO lj_entries (lj_id, blog_entry_id) VALUES (4, ?)");

while(my $h = $fetch->fetchrow_hashref)
{
	my $id = $h->{id};
	my $title = $h->{title};
	print "$id $title\n";
	$insert->execute($id);
}
