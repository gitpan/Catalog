use Cwd;
use Catalog;

require "conf/lib.pl";

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

#
# Copy and modify configuration files for test
#
sub conftest {
    my($mysql_conf) = load_config("conf/mysql.conf");
    $mysql_conf->{'base'} = 'test';
    $mysql_conf->{'host'} = 'localhost';
    $mysql_conf->{'port'} = '7777';
    my($cwd) = getcwd();
    $mysql_conf->{'unix_port'} = "$cwd/t/tmp/db.sock";
    $mysql_conf->{'user'} = undef;
    $mysql_conf->{'passwd'} = undef;
    unload_config($mysql_conf, "conf/mysql.conf", "t/conf/mysql.conf");

    my($install_conf) = load_config("conf/install.conf");
    unload_config($install_conf, "conf/install.conf", "t/conf/install.conf");
}

sub rundb {
    conftest();
    my($mysql_conf) = load_config("t/conf/mysql.conf");
    my($mysqld) = "$mysql_conf->{'home'}/libexec/mysqld";
    $mysqld = "$mysql_conf->{'home'}/sbin/mysqld" unless(-f $mysqld && -x $mysqld);
    error("$mysqld is not an executable file") unless(-f $mysqld && -x $mysqld);
    if(-f "t/tmp/db.pid") {
	system("kill -15 `cat t/tmp/db.pid` 2>/dev/null");
    }
    system("rm -fr t/tmp/db");
    mkdir("t/tmp/db", 0777);
    my($mysql_opt) = "--port $mysql_conf->{'port'} --socket $mysql_conf->{'unix_port'}";
    my($cwd) = getcwd();
    my($cmd) = "$mysqld --skip-grant-table --datadir=$cwd/t/tmp/db --pid-file $cwd/t/tmp/db.pid $mysql_opt > /dev/null 2>&1 &";
    system($cmd);
    #
    # Wait a bit for the server to start
    #
    system("sleep 3");
    system("$mysql_conf->{'home'}/bin/mysql $mysql_opt -e 'create database test'");
}

sub stopdb {
#
# Cleanup
#
    system("rm t/conf/mysql.conf t/conf/install.conf ; kill -15 `cat t/tmp/db.pid`");
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
