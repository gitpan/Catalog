#
# $Header: /usr/local/cvsroot/Catalog/t/03dmoz.t,v 1.6 1999/07/01 17:51:09 loic Exp $
#
use strict;

use Test;
use Catalog::dmoz;

require "t/lib.pl";

plan test => 2;

conftest_generic();
create_catalogs();

$ENV{'PATH'} = "bin:$ENV{'PATH'}";

my($catname) = 'dmoz';

#$::opt_verbose = 'normal';
#$::opt_fake = 1;

local($SIG{__DIE__});

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
$catalog->cimport_dmoz_api('t/rdf', 'convert');
$catalog->cimport_dmoz_api('t/rdf', 'load');
my($count) = $catalog->db()->exec_select_one("select count(*) as count from dmozrecords")->{'count'};
print "\n"; # finish gauge line
ok($count == 159, 1, "import t/rdf/content.rdf $count records in dmozrecords instead of 159");
$count = $catalog->db()->exec_select_one("select count(*) as count from catalog_path_dmoz")->{'count'};
ok($count == 45, 1, "import t/rdf/content.rdf $count path in catalog_path_dmoz instead of 45");
$catalog->close();
system("rm t/rdf/dmoz.rdf");
}
show_size();

conftest_generic_clean();

# Local Variables: ***
# mode: perl ***
# End: ***
