sub load_config {
    my($config) = @_;

    my(%record);
    open(FILE, "<$config") || die "cannot open $config for reading : $!";
    while(<FILE>) {
        my($var, $value) = /^([a-z0-9_]+)\s*=\s*(.*?)\s*$/io;
	if(defined($var)) {
	    $record{$var} = $value;
	}
    }
    close(FILE);

    return \%record;
}

sub unload_config {
    my($record, $config_from, $config_to) = @_;

    $config_to = $config_from if(!defined($config_to));

    my($buffer);
    open(FILE, "<$config_from") || die "cannot open $config_from for reading : $!";
    while(<FILE>) {
        my($var) = /^([a-z0-9_]+?)\s*=/io;
	($var) = /^\s*#([a-z0-9_]+?)\s*=/io if(!defined($var));

	if(defined($var) && exists($record->{$var})) {
	    if(defined($record->{$var})) {
		$buffer .= "$var = $record->{$var}\n";
	    } else {
		$buffer .= "#$var = \n";
	    }
	} else {
	    $buffer .= $_;
	}
    }
    close(FILE);

    system("cp $config_to $config_to.orig") if(! -f "$config_to.orig" && $config_from eq $config_to);
    open(FILE, ">$config_to") || die "cannot open $config_to for writing : $!";
    print FILE $buffer;
    close(FILE);
}

sub conf2opt {
    my($mysql_conf) = @_;
    
    my(%map) = (
		'user' => 'user',
		'passwd' => 'password',
		'port' => 'port',
		'host' => 'host',
		'unix_port' => 'socket',
		);
    my($opt) = '';
    my($key);
    foreach $key ('user', 'passwd', 'port', 'host', 'unix_port') {
	$opt .= " --$map{$key}='$mysql_conf->{$key}'" if(defined($mysql_conf->{$key}) && $mysql_conf->{$key} !~ /^\s*$/o);
    }

    $mysql_conf->{'cmd_opt'} = $opt;
}

1;
