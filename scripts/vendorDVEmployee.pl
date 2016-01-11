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
my $sth = $dbh->prepare("Select D.Fdoc_Nbr, D.Dv_Payee_Prsn_Nm, D.Dv_Pmt_Reas_Cd, F.Dv_Chk_Tot_Amt, E.aprv_dt, A.Vndr_Hdr_Gnrtd_Id, A.Vndr_Nm  
  From
    (Select Replace(Vndr_Nm, ' ', '') As Name, Vndr_Hdr_Gnrtd_Id, Vndr_Nm From KFS.Pur_Vndr_Dtl_T) A,
    CYNERGY.Krim_Entity_Nm_T\@cynprod B,
    KFS.Fp_Dv_Payee_Dtl_T D,
    CYNERGY.Krew_Doc_Hdr_T\@Cynprod E,
    KFS.FP_DV_DOC_T F
  Where D.Fdoc_Nbr = E.Doc_Hdr_Id
    AND A.Name = Trim(B.Last_Nm) || ',' || Trim(B.First_Nm) || Trim(B.Middle_Nm)
    AND A.Vndr_Hdr_Gnrtd_Id = Substr(D.Dv_Payee_Id_Nbr, 0, Instr(D.Dv_Payee_Id_Nbr, '-') - 1)
    And D.Dv_Payee_Typ_Cd = 'V'
    And D.Dv_Pmt_Reas_Cd In ('A', 'E', 'L', 'O', 'S')
    And D.Fdoc_Nbr = E.Doc_Hdr_Id
    And E.Aprv_Dt > Sysdate - 30
    And D.Fdoc_Nbr = F.Fdoc_Nbr");

$sth->execute();

open(CSV, "> vendorDVEmployee.csv");

print "Content-type: text/html\n\n";

print "<a href='vendorDVEmployee.csv'>Download as csv</a><br><br>\n";

print "<table>\n";
print "<tr><th>FDOC_NBR</th><th>DV_PAYEE_PRSN_NM</th><th>DV_PMT_REAS_CD</th><th>DV_CHK_TOT_AMT</th><th>APRV_DT</th><th>VNDR_HDR_GNRTD_ID</th><th>VNDR_NM</th></tr>\n";
print CSV "FDOC_NBR,DV_PAYEE_PRSN_NM,DV_PMT_REAS_CD,DV_CHK_TOT_AMT,APRV_DT,VNDR_HDR_GNRTD_ID,VNDR_NM\n";

while (my $ref = $sth->fetchrow_hashref()) {
  print CSV "\"$ref->{FDOC_NBR}\",\"$ref->{DV_PAYEE_PRSN_NM}\",\"$ref->{DV_PMT_REAS_CD}\",\"$ref->{DV_CHK_TOT_AMT}\",\"$ref->{APRV_DT}\",\"$ref->{VNDR_HDR_GNRTD_ID}\",\"$ref->{VNDR_NM}\"\n";
  print "<tr><td><a href='https://cynergy.cornell.edu/cynergy/kew/DocHandler.do?docId=$ref->{FDOC_NBR}&command=displayActionListView' target='_blank'>$ref->{FDOC_NBR}</a></td><td>$ref->{DV_PAYEE_PRSN_NM}</td><td>$ref->{DV_PMT_REAS_CD}</td><td>$ref->{DV_CHK_TOT_AMT}</td><td>$ref->{APRV_DT}</td><td>$ref->{VNDR_HDR_GNRTD_ID}</td><td>$ref->{VNDR_NM}</td></tr>\n";
}

close(CSV);
$dbh->disconnect;
