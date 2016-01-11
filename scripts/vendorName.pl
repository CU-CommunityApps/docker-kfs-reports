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
my $sth = $dbh->prepare("select vndr_hdr_gnrtd_id, vndr_dtl_asnd_id, vndr_nm from KFS.pur_vndr_dtl_t where LENGTH(vndr_nm) > 40" );
$sth->execute();

open(CSV, "> vendorfile.csv");

print "Content-type: text/html\n\n";

print "<a href='vendorfile.csv'>Download as csv</a><br><br>\n";

print "<table>\n";
print "<tr><th>vndr_hdr_gnrtd_id</th><th>vndr_dtl_asnd_id</th><th>vndr_nm</th></tr>\n";

while (my $ref = $sth->fetchrow_hashref("NAME_lc")) {
  $ref->{TTL} =~ s/,//;

  print CSV "$ref->{vndr_hdr_gnrtd_id},$ref->{vndr_dtl_asnd_id}, $ref->{vndr_nm}\n";
  print "<tr><td>$ref->{vndr_hdr_gnrtd_id}</td><td>$ref->{vndr_dtl_asnd_id}</td><td>$ref->{vndr_nm}</td></tr>\n";
}

close(CSV);
$dbh->disconnect;
