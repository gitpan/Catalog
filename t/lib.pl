use Cwd;
use Catalog;

#
# Pretend we are in a mod_perl environment
#
$ENV{'GATEWAY_INTERFACE'} = 'CGI-Perl';

#$::opt_verbose = 'RDF';
#$::opt_error_stack = 'yes';

#
# Run a private mysqld daemon to prevent accidental polution
#
mkdir("t/tmp", 0777) if(! -d "t/tmp");
my($mysqld) = "t/tmp/mysqld";
my($mysql_port) = "7777";

if(! -f $mysqld) {
    open(IN, "</dev/tty") or die "cannot open /dev/tty for reading: $!";
    open(OUT, ">/dev/tty") or die "cannot open /dev/tty for writing: $!";
    print OUT "\nThe test procedure will run a private mysql server. You must
provide the full pathname of the mysqld executable file.
";
    my($default_path) = "/usr/sbin/mysqld";
    my($path) = "_unlikely_";
    while(! -f $path) {
	print OUT "mysqld path [$default_path] : ";
	$path = <IN>;
	chop($path);
	$path = $default_path if(!$path);

	if($path !~ /^\//) {
	    print OUT "$path is not an absolute pathname\n";
	} elsif(! -f $path) {
	    print OUT "$path is not an existing file\n";
	} else {
	    system("$path --version | grep Ver > /dev/null 2>&1");
	    if($? != 0) {
		print OUT "$path --version does not work ? Is it really mysqld the executable ?\n";
		$path = "_unlikely_";
	    } else {
		system("ln -s $path $mysqld");
	    }
	}
    }
    close(IN);
    close(OUT);
}

sub rundb {
    my($cwd) = getcwd();
    if(-f "t/tmp/db.pid") {
	system("kill -15 `cat t/tmp/db.pid` 2>/dev/null");
    }
    system("rm -fr t/tmp/db");
    mkdir("t/tmp/db", 0777);
    my($cmd) = "$mysqld --skip-grant-table --port $mysql_port --datadir=$cwd/t/tmp/db --pid-file $cwd/t/tmp/db.pid --socket $cwd/t/tmp/db.sock > /dev/null 2>&1 &";
    system($cmd);
    #
    # Wait a bit for the server to start
    #
    system("sleep 3");
    system("mysql --port $mysql_port --socket $cwd/t/tmp/db.sock -e 'create database test'");
}

sub stopdb {
#
# Cleanup
#
    system("kill -15 `cat t/tmp/db.pid`");
    system("sleep 3");
}

#
# cgi output directory
#
mkdir("t/tmp/html", 0777) if(!-d "t/tmp/html");
#
# Template files
#
$ENV{'TEMPLATESDIR'} = "t/templates";
#
# Configuration files
#
$ENV{'CONFIG_DIR'} = "t/conf";
#
# Simulate cgi environment
#
$ENV{'REQUEST_METHOD'} = "GET";
#
# Synchronize stdout with stderr
#
$| = 1;

#
# Extract current process size in bytes (ONLY WORKS on RedHat-5.2)
#
sub size {
    open(FILE, "</proc/$$/stat");
    my($a) = <FILE>;
    close(FILE);
    my(@a) = split(' ', $a);
#    print "pid = $a[0]\n"; 
    return $a[22];
}

my($mem_size);

#sub mem_size { $mem_size = size(); print STDERR "$mem_size -> " }
#sub show_size { $mem_size = size(); print STDERR "$mem_size\n" }
sub mem_size {}
sub show_size {}

#
# Assuming that the external var $html contains an HTML page
# with hidden params, push them in $cgi. Sort of emulate a POST...
# If $re is set, only params matching $re will be sniffed
#
sub param_snif {
    my($cgi, $html, $re) = @_;

    while($html =~ /type=hidden.*name=(.*?)\s*value="(.*)"/go) {
	my($var, $value) = ( $1, $2 );
	next if(defined($re) && $var !~ /$re/);
	$value =~ s/&amp;/&/g;
	$value =~ s/%2C/,/g;
#    print STDERR "$var => $value\n";
	$cgi->param($var => $value) if($value);
    }
}

sub create_catalogs {
    my($catalog) = Catalog->new();
    $catalog->csetup_api();
    $catalog->close();
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
