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
                      ) || die "Database connection not made:\n$DBI::errstr\n";

# Now retrieve data from the table.
my $stmt = "SELECT * " . 
           "FROM KFS.DOCS_with_future_reversal_dt " . 
           "ORDER BY reversal_date ASC";
my $sth = $dbh->prepare($stmt) || die "Database view is unavailable:\n$DBI::errstr\n";
$sth->execute();

open(CSV, "> docs_with_future_reversal_dates.csv");
print "Content-type: text/html\n\n";

print "<a href='docs_with_future_reversal_dates.csv'>Download as csv</a><br><br>\n";

print "<table>\n";
print "<tr><th> Doc Type Code </th><th> Doc # </th><th> Create Date </th><th> Reversal Date </th><th> Principal Name (netid) </th></tr>\n";
print CSV "Doc Type Code, Doc #, Create Date, Reversal Date, Principal Name (netid)\n";

while (my $ref = $sth->fetchrow_hashref()) {
  $ref->{TTL} =~ s/,//;

  print CSV "$ref->{TYPE_CODE}, $ref->{DOC_NBR}, $ref->{CREATE_DATE}, $ref->{REVERSAL_DATE}, $ref->{PRINCIPAL_NAME}\n";
  print "<tr><td>$ref->{TYPE_CODE}</td><td>$ref->{DOC_NBR}</td><td>$ref->{CREATE_DATE}</td><td>$ref->{REVERSAL_DATE}</td><td>$ref->{PRINCIPAL_NAME}</td></tr>\n";
}
close(CSV);
$dbh->disconnect;
