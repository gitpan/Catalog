# This -*- perl -*- script writes the Makefile for Catalog

require 5.004;
use strict;

#--- Configuration section ---

my @programs_to_install = qw(Catalog);

use ExtUtils::MakeMaker;

print "Checking for DBI......";
eval {
    require DBI;
    DBI->require_version('1.02');
};
if ($@) {
    print " failed\n";
    print <<EOT;
$@
Catalog needs DBI module, version >= 1.02)
EOT
    exit;
} else {
    print " ok\n";
}

print "Checking for DBD::mysql......";
eval {
    require DBI;
    require DBD::mysql;
    die "" if($DBD::mysql::VERSION < 2.0210);
};
if ($@) {
    print " failed\n";
    print <<EOT;
$@
Catalog needs MySQL with perl interface installed (DBI and 
DBD::mysql, version >= 2.0210)
EOT
    exit;
} else {
    print " ok\n";
}

print "Checking for MD5......";
eval {
    require MD5;
    die "" if($MD5::VERSION < 1.7);
};
if ($@) {
    print " failed\n";
    print <<EOT;
$@
Catalog needs MD5 module, version >= 1.7)
EOT
    exit;
} else {
    print " ok\n";
}

print "Checking for CGI......";
eval {
    require CGI;
    die "" if(CGI->version() < '2.46');
};
if ($@) {
    print " failed\n";
    print <<EOT;
$@
Catalog needs CGI module, version >= 2.46
EOT
    exit;
} else {
    print " ok\n";
}

system("perl -pi -e 's/Ecila::/Catalog::/g' lib/Catalog/tools/*.pm");

my($config) = "config.cache";
if(-f $config) {
    open(FILE, "<$config") || die "cannot open $config for reading : $!";
    while(<FILE>) {
        my($var, $value) = /^(.*?)\s*=\s*(.*)$/;
        $ENV{$var} = $value;
    }
    close(FILE);
}

sub getpath {
    my($var, $prompt, $default_action, $mandatory) = @_;

    if(!exists($ENV{$var}) ||
       (defined($ENV{$var}) && $ENV{$var} ne '' && ! -d $ENV{$var})) {
	print $prompt;
	do {
	    $ENV{$var} = <STDIN>;
	    chop($ENV{$var});
	    if($ENV{$var} !~ /^\s*$/o) {
		if(! -d $ENV{$var}) {
		    print "$ENV{$var} is not a directory : ";
		}
	    } else {
		print "$default_action\n";
		if(defined($mandatory)) {
		    print $prompt;
		    $ENV{$var} = '/_fake_';
		}
	    }
	} while($ENV{$var} !~ /^\s*$/o && ! -d $ENV{$var});
    }
}

print "
Consider editing the config.cache file to fix a mistake
when perl Makefile.PL completes. This file contains all the environment
variables collected by perl Makefile.PL. 
";

getpath('INFODIR', "
The absolute pathname of the directory where the 'info'
documentation will be installed: INFODIR=[none] ", "info documentation will not be formated");
getpath('CGIDIR', "
The absolute pathname of the directory where the cgi-bin
scripts will be installed: CGIDIR=[none] ", "You must specify an existing directory", "mandatory");

if(!exists($ENV{'CGIPATH'}) || $ENV{'CGIPATH'} =~ /^\s*$/o) {
    $ENV{'CGIPATH'} = '/cgi-bin' if(!exists($ENV{'CGIPATH'}));
    print "
What is the CGIPATH corresponding to CGIDIR
($ENV{'CGIDIR'}) ? 
CGIPATH must be the path used to access the cgi-bin located in CGIDIR
when browsing from the WEB. For instance, if CGIDIR is 
/home/httpd/cgi-bin, the CGIPATH is very likely to be /cgi-bin:
CGIDIR=[$ENV{'CGIPATH'}] : ";
    my($done);
    do {
       $ENV{'CGIPATH'} = <STDIN>;
       chop($ENV{'CGIPATH'});
       if($ENV{'CGIPATH'} =~ /^\s*$/) {
	   $ENV{'CGIPATH'} = '/cgi-bin';
           $done = 1;
       } elsif($ENV{'CGIPATH'} !~ /^\//) {
	   print "You must specify an absolute path: CGIPATH=[/cgi-bin]: ";
       } else {
	   $done = 1;
       }
    } while(!$done);
    print "CGIPATH set to $ENV{'CGIPATH'}\n";
}

getpath('CONFIG_DIR', "
The absolute pathname of the directory where the default
configuration files will be installed. If not specified the 
default configuration files will be installed in the CGIDIR 
directory. CONFIG_DIR=[none] ", "CONFIG_DIR set to CGIDIR ($ENV{'CGIDIR'})");

if($ENV{'CONFIG_DIR'} =~ /^\s*$/) {
    $ENV{'CONFIG_DIR'} = $ENV{'CGIDIR'};
}

getpath('HTMLDIR', "
The absolute pathname of the directory where the HTML
material (documentation, images, examples) will be installed. It is
a good idea to put all this in a sub directory specific to Catalog so
that it will not interfere with other applications: HTMLDIR=[none] ", "You must specify an existing directory", "mandatory");
$::sqleditconf = "$ENV{'CONFIG_DIR'}/sqledit.conf";
if(! -f $::sqleditconf) {
    if(!exists($ENV{'HTMLPATH'}) || $ENV{'HTMLPATH'} =~ /^\s*$/o) {
        $ENV{'HTMLPATH'} = '/Catalog' if(!exists($ENV{'HTMLPATH'}));
	print "
What is the HTMLPATH corresponding to HTMLDIR
($ENV{'HTMLDIR'}) ? 
HTMLPATH must be the path used to access the files located in HTMLDIR
when browsing from the WEB. For instance, if HTMLDIR is 
/home/httpd/htdocs/Catalog, the HTMLPATH is very likely to be /Catalog:
HTMLPATH=[$ENV{'HTMLPATH'}] : ";
	my($done);
	do {
	    $ENV{'HTMLPATH'} = <STDIN>;
	    chop($ENV{'HTMLPATH'});
	    if($ENV{'HTMLPATH'} =~ /^\s*$/) {
		$ENV{'HTMLPATH'} = '/Catalog';
                $done = 1;
	    } elsif($ENV{'HTMLPATH'} !~ /^\//) {
		print "You must specify an absolute path: HTMLPATH=[/Catalog]: ";
	    } else {
		$done = 1;
            }
	} while(!$done);
	print "HTMLPATH set to $ENV{'HTMLPATH'}\n";
    }
} else {
    print "\nHTMLPATH will not be changed because sqledit configuration
file already exists. If you want to change it, edit 
$::sqleditconf manualy to change/add something like:
#
# Location of Catalog HTML material
#
htmlpath = /Catalog
";
}

if(!exists($ENV{'USERID'}) || $ENV{'USERID'} =~ /^\s*$/o) {
    print "
What is the userid of the HTTP server ? The default configuration
files will be copied in this directory. The HTML interface must
be able to modify them, therefore their owner must be the same as 
the userid of the HTTP server. USERID=[nobody] : ";
    $ENV{'USERID'} = <STDIN>;
    chop($ENV{'USERID'});
    if($ENV{'USERID'} =~ /^\s*$/) {
	$ENV{'USERID'} = 'nobody';
    }
}

$::mysqlconf = "$ENV{'CONFIG_DIR'}/mysql.conf";

my($ok) = 0;
my($user, $passwd);

sub dbconnect {
    translateauth();
    my($cmd) = "mysql $ENV{'MYSQL_OPT'} -e 'show tables' mysql";
    system("echo 'Trying to connect with: $cmd'");
    system("echo '------- Test output begin -----------'");
    system($cmd);
    my($status) = !$?;
    system("echo '------- Test output end   -----------'");
    return $status;
}

sub translateauth {
    ($user, $passwd) = split(':', $ENV{'AUTH'});
    $ENV{'MYSQL_OPT'} = '';

    $ENV{'MYSQL_OPT'} .= " --user='$user'" if($user);
    $ENV{'MYSQL_OPT'} .= " --password='$passwd'" if($passwd);
}

if(exists($ENV{'AUTH'})) {
    $ok = dbconnect($user, $passwd);
}

if(!$ok) {
print "
You should now specify the user name and passwd that must be used to
connect to the database. If no user or passwd are necessary leave these
values empty.
";
}
while(!$ok) {
    if(defined($user)) {
        print "Unable to connect to the database using user '$user' and password '$passwd'.\n";
    }

    my($default_user) = defined($user) ? $user : '';
    print "user [$default_user] : ";
    $user = <STDIN>;
    chop($user);
    $user = $default_user if(!$user);
    
    my($default_passwd) = defined($passwd) ? $passwd : '';
    print "passwd [$default_passwd] : ";
    $passwd = <STDIN>;
    chop($passwd);
    $passwd = $default_passwd if(!$passwd);
    $ENV{'AUTH'} = "$user:$passwd";
    $ok = dbconnect($user, $passwd);
}

print "The connection was successfull\n";

if(!-f $::mysqlconf) {
    my($usersub) = $user ? "s/^user.*/user = $user/" : "s/^user.*/#user = /";
    my($passwdsub) = $passwd ? "s/^passwd.*/passwd = $passwd/" : "s/^passwd.*/#passwd = /";
    $::mysqlpatch = "\tperl -pi -e '$usersub; $passwdsub;' $::mysqlconf\n";
    $::mysqlpatch .= "\t-chown $ENV{'USERID'} $::mysqlconf\n";
} else {
    print "\nThe existing $::mysqlconf will NOT be modified for user and passwd\n";
    $::mysqlpatch = '';
}

if(! -f $::sqleditconf) {
    my($htmlpathsub) = "s/^htmlpath.*/htmlpath = $ENV{'HTMLPATH'}";
    $::sqleditpatch = "\tperl -pi -e '$htmlpathsub;' $::sqleditconf\n";
    $::sqleditpatch .= "\t-chown $ENV{'USERID'} $::sqleditconf\n";
} else {
    $::sqleditpatch = '';
}

open(FILE, ">$config") || die "cannot open $config for writing : $!";
my($var, $value);
foreach $var (qw(CGIDIR CGIPATH CONFIG_DIR HTMLDIR HTMLPATH INFODIR USERID AUTH)) {
    print FILE "$var\t=\t$ENV{$var}\n";
}
print FILE "MYSQL_OPT\t=\t$ENV{'MYSQL_OPT'}\n";
close(FILE);

print "\nConfiguration summary:\n";
system("cat config.cache");

push(@ARGV, "INSTALLSCRIPT=$ENV{'CGIDIR'}");

sub MY::postamble { 
my($all_rules) = '';
my($install_rules) = '';
system("which texi2html > /dev/null");
if($? == 0) {
    $all_rules .= "\tcd doc ; \$(MAKE) all_html\n";
    $install_rules .= "\tcd doc ; \$(MAKE) HTMLDIR='$ENV{'HTMLDIR'}' install_html\n";
}
if($ENV{'INFODIR'} !~ /^\s*$/o) {
    $all_rules .= "\tcd doc ; \$(MAKE) all_info\n";
    $install_rules .= "\tcd doc ; \$(MAKE) INFODIR='$ENV{'INFODIR'}' install_info\n";
}

chop($install_rules) if($install_rules);
chop($all_rules) if($all_rules);

my($output) = '';
$output .= '
clean ::
	rm -fr t/fulcrum t/tmp 
	perl -pi -e "s/Catalog::/Ecila::/g" lib/Catalog/tools/*.pm
	cd doc ; $(MAKE) clean
	cd example ; $(MAKE) clean

realclean ::
	-cd images ; \
        for i in *.gif ; do \
	( cd ../doc/images ; rm -f $$i ) \
	done
	rm -f MANIFEST MANIFEST.bak config.cache

all ::
	-cd images ; \
        for i in *.gif ; do \
	( cd ../doc/images ; rm -f $$i ; cp ../../images/$$i . ) \
	done
	cd example ; $(MAKE) all
' . $all_rules . '

install::
	-cd conf ; dir=' . $ENV{'CONFIG_DIR'} . ' ; \
	for i in *.conf ; do \
	if [ ! -f $$dir/$$i ] ; then cp $$i $$dir ; chown ' . $ENV{'USERID'} . ' $$dir/$$i; fi ; \
	done
	-cd images ; dir=' . $ENV{'HTMLDIR'} . '/images ; \
	if [ ! -d $$dir ] ; then mkdir -p $$dir ; fi ; \
        for i in *.gif ; do \
	if [ ! -f $$dir/$$i ] ; then cp $$i $$dir ; chown ' . $ENV{'USERID'} . ' $$dir/$$i; fi ; \
	done
' . $::mysqlpatch . $::catalogpatch . $install_rules . '
	cd example ; $(MAKE) install
	@echo ; echo "Read the First Use chapter in the Catalog documentation "
	@echo "at http://www.senga.org/manuals.html"
	@echo "Go to the URL http://www.mymachine.org/cgi-bin/Catalog?context=ccontrol_panel"

COMPRESS = gzip -v
';
return $output;

}

WriteMakefile(
  'VERSION_FROM' => 'lib/Catalog.pm',
  'NAME'	 => 'Catalog',
  'PL_FILES'     => { map {("bin/$_.PL" => "bin/$_")} @programs_to_install },
  'EXE_FILES'    => [ map {"bin/$_"} @programs_to_install ],
  'clean'	 => { FILES => '$(EXE_FILES)' },
);

