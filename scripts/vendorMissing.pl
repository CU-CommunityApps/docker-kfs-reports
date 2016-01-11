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
my $sth = $dbh->prepare("select a.vndr_hdr_gnrtd_id, a.vndr_dtl_asnd_id, a.vndr_nm, b.vndr_typ_cd, a.vndr_pmt_term_cd, a.vndr_shp_ttl_cd, a.vndr_shp_pmt_term_cd 
                            from KFS.PUR_VNDR_DTL_T a join KFS.PUR_VNDR_HDR_T b on a.vndr_hdr_gnrtd_id=b.vndr_hdr_gnrtd_id 
                                where b.vndr_typ_cd='PO' and (a.vndr_pmt_term_cd IS NULL or a.vndr_shp_pmt_term_cd IS NULL or a.vndr_shp_ttl_cd IS NULL)");
$sth->execute();

open(CSV, "> vendormissing.csv");

print "Content-type: text/html\n\n";

print "<a href='vendormissing.csv'>Download as csv</a><br><br>\n";

print "<table>\n";
print "<tr><th>vndr_hdr_gnrtd_id</th><th>vndr_dtl_asnd_id</th><th>vndr_nm</th><th>vndr_typ_cd</th><th>vndr_pmt_term_cd</th><th>vndr_shp_ttl_cd</th><th>vndr_shp_pmt_term_cd</th></tr>\n";

while (my $ref = $sth->fetchrow_hashref("NAME_lc")) {
  $ref->{TTL} =~ s/,//;

  print CSV "$ref->{vndr_hdr_gnrtd_id},$ref->{vndr_dtl_asnd_id}, $ref->{vndr_nm}, $ref->{vndr_typ_cd}, $ref->{vndr_pmt_term_cd}, $ref->{vndr_shp_ttl_cd}, $ref->{vndr_shp_pmt_term_cd}\n";
  print "<tr><td>$ref->{vndr_hdr_gnrtd_id}</td><td>$ref->{vndr_dtl_asnd_id}</td><td>$ref->{vndr_nm}</td><td>$ref->{vndr_pmt_term_cd}</td><td>$ref->{vndr_shp_ttl_cd}</td><td>$ref->{vndr_shp_pmt_term_cd}</td><td>$ref->{vndr_addr_email_addr}</td></tr>\n";
}

close(CSV);
$dbh->disconnect; 
