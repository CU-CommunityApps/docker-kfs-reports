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
my $sth = $dbh->prepare("select PRNCPL_NM, email_addr from cynergy.krim_prncpl_t join cynergy.krim_role_mbr_t on mbr_id = prncpl_id and role_id = '54' join cynergy.krim_entity_email_t e on e.entity_id = mbr_id and (email_addr = ' ' or email_addr is null or email_addr like '%addr%')
UNION
select PRNCPL_NM, 'Missing' from cynergy.krim_prncpl_t where prncpl_id in (
select mbr_id from cynergy.krim_role_mbr_t 
  where role_id = '54' 
    and actv_ind = 'Y'
    and mbr_typ_cd = 'P' 
    and mbr_id not in (select entity_id from cynergy.krim_entity_email_t))");
$sth->execute();

open(CSV, "> missingEmail.csv");

print "Content-type: text/html\n\n";

print "<a href='missingEmail.csv'>Download as csv</a><br><br>\n";

print "<table>\n";
print "<tr><th>NETID</th><th>EMAIL</th>\n";

while (my $ref = $sth->fetchrow_hashref()) {

  print CSV "$ref->{PRNCPL_NM}, $ref->{EMAIL_ADDR}\n";
  print "<tr><td>$ref->{PRNCPL_NM}</td><td>$ref->{EMAIL_ADDR}</td></tr>\n";
}

close(CSV);
$dbh->disconnect;
