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
my $sth = $dbh->prepare("select a.vndr_hdr_gnrtd_id, b.vndr_dtl_asnd_id, c.vndr_nm, a.vndr_typ_cd, b.vndr_addr_typ_cd, b.vndr_fax_nbr, b.vndr_addr_email_addr 
                            from KFS.pur_vndr_hdr_t a, KFS.pur_vndr_addr_t b, KFS.pur_vndr_dtl_t c 
                                where a.vndr_hdr_gnrtd_id=b.vndr_hdr_gnrtd_id   
                                    and a.vndr_hdr_gnrtd_id=c.vndr_hdr_gnrtd_id 
                                    and a.vndr_typ_cd='PO' 
                                    and b.vndr_addr_typ_cd='PO'
                                     and b.vndr_fax_nbr IS NULL");
$sth->execute();

open(CSV, "> vendorfaxfile.csv");

print "Content-type: text/html\n\n";

print "<a href='vendorfaxfile.csv'>Download as csv</a><br><br>\n";

print "<table>\n";
print "<tr><th>vndr_hdr_gnrtd_id</th><th>vndr_dtl_asnd_id</th><th>vndr_nm</th><th>vndr_typ_cd</th><th>vndr_addr_typ_cd</th><th>vndr_fax_nbr</th><th>vndr_addr_email_addr</th></tr>\n";

while (my $ref = $sth->fetchrow_hashref("NAME_lc")) {
  $ref->{TTL} =~ s/,//;

  print CSV "$ref->{vndr_hdr_gnrtd_id},$ref->{vndr_dtl_asnd_id}, $ref->{vndr_nm}, $ref->{vndr_typ_cd}, $ref->{vndr_addr_typ_cd}, $ref->{vndr_fax_nbr}, $ref->{vndr_addr_email_addr}\n";
  print "<tr><td>$ref->{vndr_hdr_gnrtd_id}</td><td>$ref->{vndr_dtl_asnd_id}</td><td>$ref->{vndr_nm}</td><td>$ref->{vndr_typ_cd}</td><td>$ref->{vndr_addr_typ_cd}</td><td>$ref->{vndr_fax_nbr}</td><td>$ref->{vndr_addr_email_addr}</td></tr>\n";
}

close(CSV);
$dbh->disconnect;
