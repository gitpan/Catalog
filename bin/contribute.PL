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
$Config{'startperl'}

!GROK!THIS!

print OUT <<'!NO!SUBS!';

use strict;
use Catalog::tools::main;
use Catalog::tools::tools;

my($product);
my($base);

sub main {
    $::opt_module = 'Catalog';
    my($main) = Catalog::tools::main->new(
              ['contributor=s', '-contributor <name>', 'contributor name'],
              ['commit', '-commit', 'commit changes & ask for integration'],
              ['checkout', '-checkout', 'checkout latest branch'],
              ['diff', '-diff', 'diff since last change'],
              ['merge=s', '-merge <change>', 'merge contributor changes number <change>'],
              ['branch', '-branch', 'create contributor branch'],
              ['module', '-module <name>', 'use module <name> (default Catalog)'],
					  );

    $main->usage("missing -contributor <name>") if(!defined($::opt_contributor));

    $product = $::opt_module;
    $base = lc($::opt_module);

    my($maintainer) = 'senga@senga.org';

    if($::opt_merge || $::opt_branch) {
	pause("NOT ALLOWED TO CONTRIBUTORS return to proceed or ctrl-c to cancel ");
	if($::opt_merge) {
	    die "$product directory/file exists" if(-d $product || -f $product);
	    run("cvs checkout $product");
	    my($info) = cvsinfo('trunc');
	    my($branch) = "$base-$info->{'newest_version'}-$::opt_contributor";
	    my($from) = $::opt_merge;
	    my($to) = $from + 1;
	    run("cvs update -ko -j $branch-$from -j $branch-$to");
	} elsif($::opt_branch) {
	    my($info) = cvsinfo('trunc');
	    my($trunc) = "$base-$info->{'trunc_major'}-$info->{'trunc_next_minor'}";
	    my($branch) = "$trunc-$::opt_contributor";
	    die "$branch already exists" if($branch eq $info->{'newest_branch'});
	    mkdir("cvstmp", 0777) or die "cannot mkdir cvstmp : $!";
	    chdir("cvstmp") or die "cannot chdir cvstmp : $!";
	    run("cvs rtag $trunc $product");
	    run("cvs rtag -b -r $trunc $branch $product");
	    run("cvs checkout -r $branch $product");
	    chdir("$product") or die "cannot chdir $product : $!";
	    run("cvs tag $branch-1");
	    chdir("../..") or die "cannot chdir ../.. : $!";
	    run("rm -fr cvstmp");
	    print "Mail $::opt_contributor that $branch is ready\n";
	}
    } else {
	my($info) = cvsinfo('contributor');
	my($cmd);
	if($::opt_commit) {
	    run("cvs update");
	    run("cvs commit");
	    run("cvs tag -F $info->{'next_change'}");
	    print "Now send a mail to $maintainer to ask for integration of $info->{'next_change'}\n";
	} elsif($::opt_checkout) {
	    $cmd = ".." ; print "cd $cmd\n" ; chdir($cmd) || die "cannot chdir $cmd : $!";
	    if($info->{'newest_branch'} eq $info->{'current_branch'}) {
		print "You have already checked out the newest branch\n";
	    } else {
		my($backup) = "$product-$info->{'current_version'}";
		die "$product directory does not exist" if(! -d $product);
		die "$backup exists (regular file)" if(-f $backup);
		die "$backup exists (directory)" if(-d $backup);
		run("mv $product $backup");
		run("cvs checkout -r $info->{'newest_branch'} $product");
	    }
	} elsif($::opt_diff) {
	    run("cvs diff -c -r $info->{'current_change'} > ../$info->{'current_change'}.diff");
	}
    }
}

sub run {
    my($cmd) = @_;

    my($input) = pause("Press return to proceed, s to skip or ctrl-c to cancel\n$cmd ");
    if($input !~ /^s/io) {
	system($cmd);
    }
}

sub pause {
    my($msg) = @_;
    print $msg;
    my($input) = scalar(<>);
    chop($input);
    return $input;
}

sub cvsinfo {
    my($what) = @_;

    my(%info);

    die "must run in the directory containing the $product directory" if(! -f "$product/COPYING");
    print "cd $product\n" ; chdir($product) || die "cannot chdir $product : $!";

    if($what eq 'contributor') {
	my($file) = "CVS/Tag";
	open(FILE, "<$file") or die "cannot open $file for reading : $!";
	($info{'current_branch'}) = scalar(<FILE>) =~ /^T(.*)/;
	close(FILE);

	print "$info{'current_branch'}";
	die "$info{'current_branch'} does not contain $::opt_contributor" if($info{'current_branch'} !~ /-$::opt_contributor$/);

	($info{'current_version'}) = $info{'current_branch'} =~ /^$base-(\d+-\d+)-$::opt_contributor$/;

	die "could not extract current_version from $info{'current_branch'}" if(!defined($info{'current_version'}));
    }

    my($cmd) = "cvs log -h COPYING |";
    open(FILE, $cmd) or die "cannot open $cmd : $!";
    my($symbolic) = 0;
    while(<FILE>) {
	chop;
	if($symbolic && /^\t/) {
	    if(/^\t(.*-$::opt_contributor.*):/) {
		my($tag) = $1;
		if($tag =~ /^$base-\d+-\d+-$::opt_contributor$/) {
		    $info{'newest_branch'} = $tag if(!exists($info{'newest_branch'}));
		}
		if($tag =~ /^$info{'current_branch'}-\d+$/) {
		    if(!exists($info{'current_change'})) {
			$info{'current_change'} = $tag;
		    }
		}
		if($tag =~ /^$base-(\d+-\d+)-$::opt_contributor-(\d+)$/) {
		    if(!exists($info{'newest_change'})) {
			$info{'newest_version'} = $1;
			$info{'change_number'} = $2;
			$info{'newest_change'} = $tag;
		    }
		}
	    } elsif(/^\t$base-(\d+)-(\d+):/) {
		if(!exists($info{'trunc_major'})) {
		    $info{'trunc_major'} = $1;
		    $info{'trunc_minor'} = $2;
		    $info{'trunc_next_minor'} = $2 + 1;
		}
	    }
	} else {
	    $symbolic = /^symbolic names/o;
	}
    }
    close(FILE);

    if($what eq 'contributor') {
	$info{'next_change'} = "$info{'current_branch'}-" . ($info{'change_number'} + 1);
    }

    die "could not find trunc for $product" if(!exists($info{'trunc_major'}));

    return \%info;
}

main();

!NO!SUBS!

# Local Variables: ***
# mode: perl ***
# End: ***
