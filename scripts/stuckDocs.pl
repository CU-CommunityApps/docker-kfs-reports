#!/usr/bin/env perl
use strict;
use DBI;
use YAML qw/LoadFile/;

my $fh;
open($fh, '<', "connection_settings.yaml") or die("ERROR: Couldn't open connection_settings.yaml!\n" . $!);
my $connection_settings = YAML::LoadFile($fh);

my $dbh = DBI->connect( $connection_settings->{'cynergy_prod'}->{'datasource'},
                        $connection_settings->{'cynergy_prod'}->{'username'},
                        $connection_settings->{'cynergy_prod'}->{'password'}
                      ) || die "Database connection not made: $DBI::errstr";

# Now retrieve data from the table.
my $sth = $dbh->prepare("SELECT a.DOC_HDR_STAT_CD, a.DOC_HDR_ID, TO_CHAR(a.CRTE_DT, 'MM/DD/YY') CRTE_DT, a.TTL, TO_CHAR(a.STAT_MDFN_DT, 'MM/DD/YY')  STAT_MDFN_DT ,c.PRNCPL_NM, d.doc_typ_nm 
                                FROM CYNERGY.KREW_DOC_HDR_T A, CYNERGY.KREW_ACTN_ITM_T B, CYNERGY.KRIM_PRNCPL_T C, CYNERGY.KREW_DOC_TYP_T D  
                                    WHERE 
                                      a.doc_hdr_id = b.doc_hdr_id (+) AND
                                      a.initr_prncpl_id = c.prncpl_id  AND
                                      a.doc_typ_id = d.doc_typ_id AND
                                      a.DOC_HDR_STAT_CD ='R' AND 
                                      b.DOC_HDR_ID Is Null AND
                                      a.crte_dt > to_date('07/01/11', 'MM/DD/YY') ORDER BY a.CRTE_DT desc" );
$sth->execute();

open(CSV, "> file.csv");

print "Content-type: text/html\n\n";

print "<a href='file.csv'>Download as csv</a><br><br>\n";

print "<table>\n";
print "<tr><th>DOC_HDR_ID</th><th>DOC_TYP_NM</th><th>DOC_HDR_STAT_CD</th><th>CRTE_DT</th><th>DESCRIPTION</th><th>STAT_MDFN_DT</th><th>INITIATOR_NETID</th></tr>\n";

while (my $ref = $sth->fetchrow_hashref()) {
  $ref->{TTL} =~ s/,//;

  print CSV "$ref->{DOC_HDR_ID}, $ref->{DOC_TYP_NM},$ref->{DOC_HDR_STAT_CD}, $ref->{CRTE_DT}, $ref->{TTL}, $ref->{STAT_MDFN_DT}, $ref->{PRNCPL_NM}\n";
  print "<tr><td>$ref->{DOC_HDR_ID}</td><td>$ref->{DOC_TYP_NM}</td><td>$ref->{DOC_HDR_STAT_CD}</td><td>$ref->{CRTE_DT}</td><td>$ref->{TTL}</td><td>$ref->{STAT_MDFN_DT}</td><td>$ref->{PRNCPL_NM}</td></tr>\n";
}

close(CSV);
$dbh->disconnect;
