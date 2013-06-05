use strict;
use WebService::LiveJournal::Latest;

my $latest = new WebService::LiveJournal::Latest;
my @items = $latest->items;

my %keys;
foreach my $item (@items)
{
	foreach my $key (keys %$item)
	{
		$keys{$key}++;
	}
}

foreach my $key (sort keys %keys)
{
	print "$key = $keys{$key}\n";
}
