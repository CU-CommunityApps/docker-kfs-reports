#!/usr/bin/env perl
use strict;
use DBI;
use YAML qw/LoadFile/;

my $fh;
open($fh, '<', "connection_settings.yaml") or die("ERROR: Couldn't open connection_settings.yaml!\n" . $!);
my $connection_settings = YAML::LoadFile($fh);

my $dbh = DBI->connect( $connection_settings->{'kfs_prod'}->{'datasource'},
                        $connection_settings->{'kfs_prod'}->{'username'},
                        $connection_settings->{'kfs_prod'}->{'password'}
                      ) || die "Database connection not made: $DBI::errstr";

# Now retrieve data from the table.
my $sth = $dbh->prepare("select fdoc_typ_cd, fdoc_nbr, doc_hdr_stat_cd, transaction_dt, account_nbr from KFS.DOCS_with_invalid_gl_pend" );
$sth->execute();

open(CSV, "> nonpendingdocs.csv");
print "Content-type: text/html\n\n";

print "<a href='nonpendingdocs.csv'>Download as csv</a><br><br>\n";

print "<table>\n";
print "<tr><th>FDOC_TYP_CD</th><th>FDOC_NBR</th><th>DOC_HDR_STAT_CD</th><th>TRANSACTION_DT</th><th>ACCOUNT_NBR</th></tr>\n";

while (my $ref = $sth->fetchrow_hashref("NAME_lc")) {
  $ref->{TTL} =~ s/,//;
  
  print CSV "$ref->{FDOC_TYP_CD}, $ref->{FDOC_NBR},$ref->{DOC_HDR_STAT_CD}, $ref->{TRANSACTION_DT}, $ref->{ACCOUNT_NBR}\n";
  print "<tr><td>$ref->{FDOC_TYP_CD}</td><td>$ref->{FDOC_NBR}</td><td>$ref->{DOC_HDR_STAT_CD}</td><td>$ref->{TRANSACTION_DT}</td><td>$ref->{ACCOUNT_NBR}</td></tr>\n";
}
close(CSV);
$dbh->disconnect;
