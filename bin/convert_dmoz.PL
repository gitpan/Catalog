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
use vars qw($create $catid_max $record_max %path2catid $cgi);
use Catalog::tools::tools;
use Catalog::tools::cgi;

$create = <<'EOF';
 <Table>
  <![CDATA[
create table dmozrecords (
  #
  # Table management information 
  #
  rowid int auto_increment not null,
  created datetime not null,
  modified timestamp not null,

  info enum ('active', 'inactive') default 'active',
  url char(255),
  title char(255),
  description char(255),

  unique dmozrecord1 (rowid)
)
  ]]>
 </Table>

 <Catalog>
  <name>dmoz</name>
  <tablename>dmozrecords</tablename>
  <navigation>theme</navigation>
 </Catalog>
EOF

my($cgi) = exists($ENV{'REQUEST_METHOD'});

sub main {
    my($content, $structure, $to) = @ARGV;

    if(!defined($content) ||
       !defined($structure) ||
       !defined($to) ||
       ! -r $content || ! -r $structure) {
	print STDERR "usage: $0 content.rdf structure.rdf dmoz.rdf\n";
	return;
    }

    open(TO, ">$to") or error("cannot open $to for writing : $!");

    print TO <<'EOF';
<?xml version="1.0" encoding="ISO-8859-1" ?>
<RDF xmlns:rdf="http://www.w3.org/TR/1999/REC-rdf-syntax-19990222#"
     xmlns="http://www.ecila.fr/">
EOF
    if($content) {
	print TO $create;
	open(FROM, "<$content") or error("cannot open $content for reading : $!");
	my($buffer) = '';
	my($accumulate);
	while(<FROM>) {
	    if(/^<Topic/) {
		if($accumulate) {
		    handle_content($buffer);
		    $buffer = '';
		}
		$accumulate = 1;
	    }
	    $buffer .= $_ if($accumulate);
	    print " " if($cgi);
	}

	handle_content($buffer);
	close(FROM);
	#
	# Trigger computation of additional administrative data.
	# This data may be needed to process the structure.
	#
	print TO " <Sync/>\n";
    }
    if($structure) {
	open(FROM, "<$structure") or error("cannot open $structure for reading : $!");
	my($buffer) = '';
	my($accumulate);
	while(<FROM>) {
	    if(/^<Topic/) {
		if($accumulate) {
		    handle_structure($buffer);
		    $buffer = '';
		}
		$accumulate = 1;
	    }
	    $buffer .= $_ if($accumulate);
	    print " " if($cgi);
	}

	handle_structure($buffer);
	close(FROM);
    }

    print TO "\n</RDF>\n";
    close(TO);
}

sub fixup {
    my($string, $default) = @_;

    return $default if(!$string || $string =~ /^\s*$/so);

    $string =~ s/[\000-\037\177]//go;
    $string = Catalog::tools::cgi::myescapeHTML($string);

    return $string;
}

$catid_max = 5000000;
$record_max = 1;
%path2catid = ();

sub handle_structure {
    my($buffer) = @_;

    my($catid) = $buffer =~ m|<catid>(\d+)</catid>|so;
    return if(!defined($catid));

    my(@editors) = ();
    while($buffer =~ m|<editor r:resource=\"(.*?)\"/>|sgo) {
	my($string) = $1;
	next if(!$string || $string =~ /^\s*$/o);
	push(@editors, fixup($string, ''));
    }

    my($editor);
    foreach $editor (@editors) {
	print TO " <Auth>\n";
	print TO "  <login>$editor</login>\n";
	print TO "  <category>$catid</category>\n";
	print TO " </Auth>\n";
    }
    
    my(@newsgroups) = ();
    while($buffer =~ m|<newsGroup r:resource=\"(.*?)\"/>|sgo) {
	my($string) = $1;
	next if(!$string || $string =~ /^\s*$/o);
	push(@newsgroups, fixup($string, ''));
    }

    my($newsgroup);
    foreach $newsgroup (@newsgroups) {
	print TO " <Newsgroup>\n";
	print TO "  <url>$newsgroup</url>\n";
	print TO "  <category>$catid</category>\n";
	print TO " </Newsgroup>\n";
    }

    my(@symlinks) = ();
    while($buffer =~ m|<symbolic r:resource=\".*?:Top(.*?)\"/>|sgo) {
	my($string) = $1;
	next if(!$string || $string =~ /^\s*$/o);
	$string =~ s/_/ /go;
	next if(!exists($path2catid{$string}));
	push(@symlinks, $path2catid{$string});
    }

    my($symlink);
    foreach $symlink (@symlinks) {
	print TO " <Symlink>\n";
	print TO "  <up>$catid</up>\n";
	print TO "  <down>$symlink</down>\n";
	print TO " </Symlink>\n";
    }

    my(@relateds) = ();
    while($buffer =~ m|<related r:resource=\"Top(.*?)\"/>|sgo) {
	my($string) = $1;
	next if(!$string || $string =~ /^\s*$/o);
	$string =~ s/_/ /go;
	next if(!exists($path2catid{$string}));
	push(@relateds, $path2catid{$string});
    }

    my($related);
    foreach $related (@relateds) {
	print TO " <Related>\n";
	print TO "  <up>$catid</up>\n";
	print TO "  <down>$related</down>\n";
	print TO " </Related>\n";
    }
}

sub handle_content {
    my($buffer) = @_;

    my($path, $catid);
    ($path) = $buffer =~ m|<Topic r:id=\"Top(.*?)\">|o;
    $path =~ s/_/ /go;

    ($catid) = $buffer =~ m|<catid>(\d+)</catid>|so;
    if(!defined($catid)) {
	$catid = $catid_max++;
    }

    my($parent, $name) = $path =~ m|(.*)/(.*)|;
    $path2catid{$path} = $catid;
    #
    # Ignore root
    #
    return if(!$name);
    $name = fixup($name, 'No name');
    my($parent_id) = find_parent_id($parent);

    print TO <<EOF;

 <Category>
  <rowid>$catid</rowid>
  <name>$name</name>
  <parent>$parent_id</parent>
 </Category>
EOF

    my(@records);
    while($buffer =~ m|<ExternalPage (.*?)</ExternalPage>|sgo) {
	my($record) = $1;
	my($url, $title, $description);
	($url) = $record =~ m|about=\"(.*?)\"|so;
	($title) = $record =~ m|<d:Title>(.*)</d:Title>|so;
	($description) = $record =~ m|<d:Description>(.*)</d:Description>|so;

	push(@records, {
	    'rowid' => $record_max,
	    'url' => fixup($url, 'Nourl'),
	    'title' => fixup($title, 'No title'),
	    'description' => fixup($description, 'No description'),
	});
	$record_max++;
    }

    my($record);
    foreach $record (@records) {
	print TO <<EOF;
 <Link>
  <row>$record->{'rowid'}</row>
  <category>$catid</category>
 </Link>
EOF
    }

    foreach $record (@records) {
	print TO <<EOF;
 <Record table="dmozrecords">
  <rowid>$record->{'rowid'}</rowid>
  <url>$record->{'url'}</url>
  <title>$record->{'title'}</title>
  <description>$record->{'description'}</description>
 </Record>
EOF
    }

}

sub find_parent_id {
    my($path) = @_;

    if(exists($path2catid{$path})) {
	return $path2catid{$path};
    } else {
	my($parent, $name) = $path =~ m|(.*)/(.*)|o;
	my($parent_id) = find_parent_id($parent);
	my($path_id) = $catid_max++;
	$path2catid{$path} = $path_id;
	print TO <<EOF;
 <Category>
  <rowid>$path_id</rowid>
  <name>$name</name>
  <parent>$parent_id</parent>
 </Category>
EOF
        return $path_id;    
    }
}

main();

!NO!SUBS!

# Local Variables: ***
# mode: perl ***
# End: ***
