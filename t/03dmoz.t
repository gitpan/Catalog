#
# $Header: /spare2/ecila-cvsroot/Catalog/t/03dmoz.t,v 1.3 1999/04/14 13:33:07 ecila40 Exp $
#
use strict;

use Test;
use Catalog::dmoz;

require "t/lib.pl";

plan test => 1;

rundb();
create_catalogs();

$ENV{'PATH'} = "bin:$ENV{'PATH'}";

my($catname) = 'dmoz';

#$::opt_verbose = 'normal';
#$::opt_fake = 1;

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Import RDF file
#
";
my($catalog) = Catalog::dmoz->new();
$catalog->cimport_api($catname, "t/rdf/content.rdf");
my($count) = $catalog->exec_select_one("select count(*) as count from dmozrecords")->{'count'};
print "\n"; # finish gauge line
ok($count == 159, 1, "import t/rdf/content.rdf $count records in dmozrecords instead of 159");
$catalog->close();
}
show_size();

stopdb();

# Local Variables: ***
# mode: perl ***
# End: ***
