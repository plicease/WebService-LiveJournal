use strict;
use warnings;
use 5.012;
use autodie;
use NX;
use NX::Blog::Entry;
use YAML::XS qw( LoadFile );

my $journal_name = shift;
my $lj_account_id = shift;
my $fn = shift;

unless(defined $journal_name && defined $fn)
{
  say STDERR "usage: nx lj reverse journal_name lj_account_id fn";
  exit 2;
}

my $lj_link = NX->nx_system_db->prepare(qq{
  INSERT INTO
    lj_entries (lj_id, blog_entry_id, item_id, anum, html_id, synchronized)
  VALUES
    (?,?,?,?,?,?)
});

my($groups, @lj_entries) = LoadFile($fn);
foreach my $lj_entry (@lj_entries)
{
  my $markup_language;
  if(defined $lj_entry->{props}->{opt_preformatted} && $lj_entry->{props}->{opt_preformatted})
  {
    $markup_language = 'html';
  }
  else
  {
    $markup_language = 'html formatted';
  }

  my $entry = new NX::Blog::Entry(
    hash => {
      year => $lj_entry->{time}->{year},
      month => $lj_entry->{time}->{month},
      day => $lj_entry->{time}->{day},
      hour => $lj_entry->{time}->{hour},
      min => $lj_entry->{time}->{min},
      access_type => $lj_entry->{access_type},
      journal_name => $journal_name,
      title => $lj_entry->{title},
      msg => $lj_entry->{msg},
      markup_language => $markup_language,
    },
  );
  $entry->save;
  $lj_link->execute($lj_account_id, $entry->id, $lj_entry->{lj_entry}->{item_id}, $lj_entry->{lj_entry}->{anum}, $lj_entry->{lj_entry}->{html_id}, 't');
  if(defined $lj_entry->{props}->{taglist})
  {
    my @tags = split /\s*,\s*/, $lj_entry->{props}->{taglist};
    $entry->addTag(@tags);
    $entry->save;
  }
}


__END__
---
access_type: public
lj_entry:
  anum: 91
  html_id: 17755
  item_id: 69
msg: |-
  <p> New job starting next Wednesday.  I have a good vibe about it.  In the interview they were asking me the right sort of questions about Perl.  It involves working with Perl in a Linux/SQL/Apache environment which makes me feel like a fish in water.  The pay is good too.  I will be working hard for the next few months.</p>

  <p> I have to think up a secret code name for them.  I never really cared for Company 2 as a codename.  Nor for the company really.</p>
props:
  opt_preformatted: 1
  personifi_tags: nterms:yes
  picture_keyword: ad
  taglist: 'linux, apache, water, employment, pay, job, company 2, fish, sql, perl'
time:
  day: 06
  hour: 16
  min: 13
  month: 12
  year: 2007
title: new job
url: http://tarquinhill.livejournal.com/17755.html
