# This -*- perl -*- script writes the Makefile for Catalog

require 5.005;
use strict;

require "./lib.pl";

%::var2env = (
	      'infodir' => 'INFODIR',
	      'cgidir' => 'CGIDIR',
	      'cgipath' => 'CGIPATH',
	      'config_dir' => 'CONFIG_DIR',
	      'use_config' => 'USE_CONFIG',
	      'htmldir' => 'HTMLDIR',
	      'htmlpath' => 'HTMLPATH',
	      'userid' => 'USERID',
	      'home' => 'MYSQL_HOME',
	      'user' => 'MYSQL_USER',
	      'passwd' => 'MYSQL_PASSWORD',
	      'host' => 'MYSQL_HOST',
	      'base' => 'MYSQL_BASE',
	      'port' => 'MYSQL_PORT',
	      'unix_port' => 'MYSQL_UNIX_PORT',
	      );
$::env2var = map { $::var2env{$_} => $_ } keys(%::var2env);

sub getparam_valid {
    my($var, $value, $undefp, $silent, $spec) = @_;

    if(!defined($value)) {
	if($undefp eq 'undef_ok') {
	    print $spec->{'undef_comment'} if(!$silent);
	    return 1;
	} else {
	    return 0;
	}
    }
    
    if($value eq '') {
	if($spec->{'mandatory'}) {
	    print "this value is mandatory " if(!$silent);
	    print $spec->{'mandatory_comment'} if(!$silent && exists($spec->{'mandatory_comment'}));
	    return 0;
	} else {
	    return 1;
	}
    }

    if($spec->{'absolute'}) {
	if($value !~ m|^/|o) {
	    print "$value must be an absolute path name ";
	    return 0;
	}
    }

    if($spec->{'directory'}) {
	if(! -d $value) {
	    print "$value is not an existing directory " if(!$silent);
	    print $spec->{'directory_comment'} if(!$silent && exists($spec->{'directory_comment'}));
	    return 0;
	}
    }

    if($spec->{'postamble'}) {
	my($func) = $spec->{'postamble'};
	return 0 unless(&$func($var, $value, $undefp, $silent, $spec));
    }

    return 1;
}

sub getparam {
    my($var, $h, $spec) = @_;
    my($env) = $::var2env{$var};
    my($value) = $h->{$var};
    #
    # ENV overrides existing value
    # nothing specified : value = undef
    # empty string specified : value = ''
    # string specified : value = string
    #
    my($from_env) = 0;
    if(defined($env) && exists($ENV{$env})) {
	if($ENV{$env} !~ /^\s*$/o) {
	    $value = $ENV{$env};
	} else {
	    $value = '';
	}
	$from_env = 1;
    } else {
	if(defined($value)) {
	    if($value =~ /^\s*$/o) {
		$value = '';
	    }
	} 
    }

    #
    # If USE_DEFAULTS, only go to interactive mode if an error is
    # detected with default parameters.
    # Otherwise go to interactive mode if value is not set by 
    # the environment.
    #
    my($interactivep);
    my($undefp);
    if($ENV{'USE_DEFAULTS'}) {
	$undefp = 'undef_ok';
	$interactivep = 0;
    } else {
	$undefp = 'undef_notok';
	$interactivep = !$from_env;
    }

    #
    # Go in interactive loop if the value found in the environment 
    # is not valid or no value was found in the environment.
    #
    if(!getparam_valid($var, $value, $undefp, 'silent', $spec) || $interactivep) {
	print $spec->{'prompt'};
	my($ok) = 0;
	do {
	    print "\n(";
	    if(defined($value)) {
		if($value eq '') {
		    print "default is empty string";
		} else {
		    print "default $value";
		}
	    } else {
		print "no default";
	    }
	    print ", type '' for empty string) $var : ";
	    my($tmp);
	    $tmp = <STDIN>;
	    chop($tmp);
	    $tmp =~ s/^\s*(.*?)\s*$/$1/o;
	    $tmp = undef if($tmp eq "''");
	    if(defined($tmp) && $tmp eq '') {
		$ok = getparam_valid($var, $value, 'undef_ok', undef, $spec);
	    } else {
		if($ok = getparam_valid($var, $tmp, 'undef_ok', undef, $spec)) {
		    $value = $tmp;
		}
	    }
	} while(!$ok);
    }

    $h->{$var} = $value;
}

sub yesno {
    my($var, $h, $spec) = @_;

    my($tmp);
    if($ENV{'USE_DEFAULTS'}) {
	$tmp = $spec->{'default'} eq 'yes' ? 1 : 0;
    } else {
	print $spec->{'prompt'};
	do {
	    print " [$spec->{'default'}] : ";
	    $tmp = <STDIN>;
	    chop($tmp);
	    if($tmp =~ /^yes$/i || $tmp =~ /^y$/i) {
		$tmp = 1;
	    } elsif($tmp =~ /^no$/i || $tmp =~ /^n$/i) {
		$tmp = 0;
	    } elsif($tmp =~ /^\s*$/) {
		$tmp = $spec->{'default'} eq 'yes' ? 1 : 0;
	    } else {
		print "answer yes or no or type return to accept default ";
		$tmp = undef;
	    }
	} while(!defined($tmp));
    }

    my($yes) = defined($spec->{'value_yes'}) ? $spec->{'value_yes'} : 1;
    my($no) = defined($spec->{'value_no'}) ? $spec->{'value_no'} : 0;
    $h->{$var} = $tmp ? $yes : $no;
}

sub locate_cmds {
    my($conf, @cmds) = @_;

    my($cmd);
    foreach $cmd (@cmds) {
	my($where) = `which $cmd 2>/dev/null`;
	if($? == 0 && $where !~ /^\s*$/os) {
	    $where =~ s/\n//gs;
	    $conf->{$cmd} = $where;
	} else {
	    $conf->{$cmd} = undef;
	}
    }
}

sub misc_ask {
    my($install_conf) = load_config("install.conf");

    my(%h);
    locate_cmds($install_conf, 'texi2html', 'makeinfo', 'texi2dvi', 'dvips', 'chown');
    if(defined($install_conf->{'texi2html'})) {
	yesno('html', \%h,
		 {
		     'prompt' => "
Do you you want HTML formated documentation ? ",
		     'yesno' => 1,
		     'default' => exists($ENV{'DOC_HTML'}) ? $ENV{'DOC_HTML'} : 'yes',
		 });
    }
    if(defined($install_conf->{'makeinfo'})) {
	yesno('info', \%h,
		 {
		     'prompt' => "
Do you you want Emacs info formated documentation ? ",
		     'yesno' => 1,
		     'default' => exists($ENV{'DOC_INFO'}) ? $ENV{'DOC_INFO'} : 'no',
		 });
    }
    if(defined($install_conf->{'texi2dvi'}) &&
       defined($install_conf->{'dvips'})) {
	yesno('ps', \%h,
		 {
		     'prompt' => "
Do you you want Postscript formated documentation ? ",
		     'yesno' => 1,
		     'default' => exists($ENV{'DOC_PS'}) ? $ENV{'DOC_PS'} : 'no',
		 });
    }

    $install_conf->{'doc_all'} = '';
    $install_conf->{'doc_install'} = '';
    my($format);
    foreach $format ('info', 'html', 'ps') {
	if($h{$format}) {
	    $install_conf->{'doc_all'} .= "all_${format} ";
	    $install_conf->{'doc_install'} .= "install_${format} ";
	    if($format eq 'info') {
		getparam('infodir', $install_conf,
			 {
			     'prompt' => "
The absolute pathname of the directory where the documentation will
be installed (Emacs info format only)",
                             'mandatory' => 1,
                             'directory' => 1,
                             'absolute' => 1,
                });
	    }
	}
    }

    if($install_conf->{'chown'}) {
	my($myself) = $ENV{'LOGNAME'};
	if(!defined($myself) || $myself =~ /^\s*$/) {
	    $myself = $ENV{'USERNAME'};
	}
	if(!defined($myself) || $myself =~ /^\s*$/) {
	    $myself = $ENV{'USER'};
	}
	if(!defined($myself) || $myself =~ /^\s*$/) {
	    die "LOGNAME and USERNAME and USER are not defined";
	}
	system("echo a > /tmp/tt$$");
	system("$install_conf->{'chown'} $myself /tmp/tt$$");
	if($? != 0) {
	    $install_conf->{'chown'} = ':';
	}
	system("rm -f /tmp/tt$$");
    } else {
	$install_conf->{'chown'} = ':';
    }
    
    unload_config($install_conf, "install.conf");
}

sub install_ask {
    my($install_conf) = load_config("install.conf");

    getparam('cgidir', $install_conf,
	    {
		'prompt' => "
The absolute pathname of the directory where the cgi-bin
scripts will be installed",
                'mandatory' => 1,
                'directory' => 1,
                'absolute' => 1,
    });
    getparam('cgipath', $install_conf,
	    {
		'prompt' => "
What is the CGIPATH corresponding to CGIDIR
(CGIDIR = $install_conf->{'cgidir'}) ? 
CGIPATH must be the path used to access the cgi-bin located in CGIDIR
when browsing from the WEB. For instance, if CGIDIR is 
/home/httpd/cgi-bin, the CGIPATH is very likely to be /cgi-bin",
                'mandatory' => 1,
                'absolute' => 1,
    });
    $install_conf->{'config_dir'} = $install_conf->{'cgidir'};
    getparam('config_dir', $install_conf,
	    {
		'prompt' => "
The absolute pathname of the directory where the default
configuration files will be installed. If not specified the 
default configuration files will be installed in the CGIDIR 
directory",
                'undef_comment' => "CONFIG_DIR set to CGIDIR ($install_conf->{'cgidir'})\n",
                'directory' => 1,
                'absolute' => 1,
    });
    getparam('htmldir', $install_conf,
            {
                'prompt' => "
The absolute pathname of the directory where the HTML
material (documentation, images, examples) will be installed. It is
a good idea to put all this in a sub directory specific to Catalog so
that it will not interfere with other applications",
                'mandatory' => 1,
                'directory' => 1,
                'absolute' => 1,
    });
    getparam('htmlpath', $install_conf,
            {
                'prompt' => "
What is the HTMLPATH corresponding to HTMLDIR
($install_conf->{'htmldir'}) ? 
HTMLPATH must be the path used to access the files located in HTMLDIR
when browsing from the WEB. For instance, if HTMLDIR is 
/home/httpd/htdocs/Catalog, the HTMLPATH is very likely to be /Catalog",
                'mandatory' => 1,
                'absolute' => 1,
    });
    getparam('userid', $install_conf,
            {
                'prompt' => "
What is the userid of the HTTP server ? The default configuration
files will be copied in the 
$install_conf->{'config_dir'} directory.
The HTML interface must be able to modify them, therefore their 
owner must be the same as the userid of the HTTP server",
                'mandatory' => 1,
    });

    unload_config($install_conf, "install.conf");
}

sub mysql_ask {
    my($mysql_conf) = load_config("mysql.conf");

    if(!$ENV{'USE_DEFAULTS'}) {
	print "
You will now be prompted for the parameters that allow a connection
to the MySQL database to be established.

";
    }

    my($ok);
    do {
	getparam('home', $mysql_conf,
		 {
		     'prompt' => "Directory in which MySQL is installed. For instance
if you have /usr/local/include/mysql then the directory is /usr/local.",
		     'mandatory' => 1,
		     'directory' => 1,
		     'absolute' => 1,
		     'postamble' => sub {
			 my($var, $value, $undefp, $silent, $spec) = @_;
			 my($include) = "$value/include/mysql";
			 if(! -d $include) {
			     print "$include is not a directory " if(!$silent);
			     return 0;
			 }
			 return 1;
		     },
		 });
	getparam('base', $mysql_conf,
		 {
		     'prompt' => "MySQL database where the catalog tables will be created.
The mysql database is created when you installed MySQL. You can
use it if you don't want to create your own.",
		     'mandatory' => 1,
		 });
	getparam('user', $mysql_conf,
		 {
		     'prompt' => "MySQL user only if not running with --skip-grant-tables",
		 });
	getparam('passwd', $mysql_conf,
		 {
		     'prompt' => "MySQL password  only if not running with --skip-grant-tables",
		 });
	getparam('host', $mysql_conf,
		 {
		     'prompt' => "MySQL host if not localhost",
		 });
	getparam('port', $mysql_conf,
		 {
		     'prompt' => "MySQL port if not default port",
		 });
	getparam('unix_port', $mysql_conf,
		 {
		     'prompt' => "MySQL socket if not default socket. 
This is only needed if running more than one MySQL server on the same host.
If you don't know what this is about, leave it empty.",
                 });
	conf2opt($mysql_conf);
	$ok = dbconnect($mysql_conf);
	if(!$ok) {
	    print "
Please fix the mysql parameters so that a connection can be established.
";
	    delete($ENV{'USE_DEFAULTS'});
	    my($key);
	    foreach $key (qw(MYSQL_BASE MYSQL_USER MYSQL_PASSWORD MYSQL_HOST MYSQL_BASE MYSQL_PORT)) {
		delete($ENV{$key});
	    }
	}
    } while(!$ok);

    unload_config($mysql_conf, "mysql.conf");
}

my($ok) = 0;
my($user, $passwd);

sub dbconnect {
    my($mysql_conf) = @_;

    my($opt) = $mysql_conf->{'cmd_opt'};
    
    my($cmd) = "mysql $opt -e \"show tables\" mysql";
    system("echo 'Trying to connect with: $cmd'");
    system("echo '------- Test output begin -----------'");
    my($unset) = "unset MYSQL_BASE ; unset MYSQL_USER ; unset MYSQL_PASSWORD ; unset MYSQL_HOST ; unset MYSQL_BASE ; unset MYSQL_PORT ; unset MYSQL_UNIX_PORT";
    system("$unset ; $cmd");
    my($status) = !$?;
    system("echo '------- Test output end   -----------'");
    return $status;
}

#
# Reuse an existing configuration
#
sub search_conf {
    my(%conf);

    getparam('use_config', \%conf,
	     {
		 'prompt' => "
Shall I take default configuration values from an existing configuration ? If yes specify the
directory. If no just type return and we will proceed with questions.
",
                 'directory' => 1,
                 'absolute' => 1,
		 'postamble' => sub {
		     my($var, $value, $undefp, $silent, $spec) = @_;

		     if(! -f "$value/mysql.conf" || ! -f "$value/install.conf") {
			 print "$value directory must contain mysql.conf and install.conf " if(!$silent);
			 return 0;
		     }
		     return 1;
		 },
    });

    if(-d "$conf{'use_config'}") {
	my($file);
	foreach $file (qw(install.conf mysql.conf)) {
	    system("cp $file $file.orig") if(! -f "$file.orig");
	    system("cp $conf{'use_config'}/$file $file");
	}
	$ENV{'USE_DEFAULTS'} = 1;
    }
}

search_conf();
install_ask();
misc_ask();
mysql_ask();
