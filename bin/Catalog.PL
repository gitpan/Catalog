use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w

!GROK!THIS!

print OUT <<'!NO!SUBS!';

use strict;

use Catalog;

Catalog->selector();

__END__

=head1 NAME

Catalog - Resources catalog management and display

=head1 DESCRIPTION

Catalog is the cgi-bin interface to all the functionalities. 
For a complete documentation about Catalog, see the installed
HTML documentation or the on-line documentation at http://www.senga.org/.

=head1 AUTHOR

Loic Dachary (loic@seng.org) http://www.senga.org/

!NO!SUBS!

# Local Variables: ***
# mode: perl ***
# End: ***
