# This -*- perl -*- script writes the Makefile for Catalog

require 5.005;
use strict;

#--- Configuration section ---

my(@programs_to_install) = qw(convert_dmoz contribute);

use ExtUtils::MakeMaker;

sub version_check {
    my($what, $min_version, $test) = @_;

    print "Checking for $what... ";
    $test .= "; die '' if(\$${what}::VERSION < \$min_version); \$${what}::VERSION";
    my $got_version = eval $test;
	$got_version = "undef" unless defined $got_version;
    if ($@) {
	print " failed\n";
	print <<EOT;
$@
Catalog needs $what module, version >= $min_version
EOT
        exit;
    } else {
        eval "print \" \$${what}::VERSION ok\n\"";
    }
}

version_check('DBI', '1.02', 'require DBI;');
version_check('DBD::mysql', '2.0210', 'require DBI; require DBD::mysql;');
version_check('MD5', '1.7', 'require MD5;');
version_check('CGI', '2.46', 'require CGI;');
version_check('XML::Parser', '2.22', 'require XML::Parser;');
version_check('XML::DOM', '1.19', 'require XML::DOM;');
version_check('MIME::Base64', '2.11', 'require MIME::Base64;');
version_check('Unicode::String', '2.02', 'require Unicode::String;');
version_check('Unicode::Map8', '0.06', 'require Unicode::Map8;');

my($subdirs) = "cgi-bin conf example images doc";

system("perl -pi -e 's/Ecila::/Catalog::/g' lib/Catalog/tools/*.pm");

#
# Wait for Unicode::String 1.20 to fix CORE:: warnings
#
sub ExtUtils::MM_Unix::test_via_harness {
    my($self, $perl, $tests) = @_;
    $perl = "PERL_DL_NONLAZY=1 $perl" unless $ExtUtils::MM_Unix::Is_Win32;
    "\t$perl".q! -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use Test::Harness qw(&runtests $$verbose $$switches); $$verbose=$(TEST_VERBOSE); $$switches = ""; runtests @ARGV;' !."$tests\n";
}

sub MY::postamble { 
return '
clean ::
	rm -fr t/fulcrum t/tmp t/conf/mysql.conf t/conf/install.conf
	perl -pi -e "s/Catalog::/Ecila::/g" lib/Catalog/tools/*.pm 

ptags:
	ptags lib/*pm lib/*/*.pm lib/*/tools/[cmst]*.pm

cvs_diff_tag :
	$(MAKE) realclean
	cvs diff -c -r`sed "s/^T//" CVS/Tag` > `sed "s/^T//" CVS/Tag`-`date "+%Y%m%d"`.diff

realclean ::
	rm -fr MANIFEST MANIFEST.bak Catalog-*

install:: 
	for i in ' . $subdirs . ' ; do ( cd $$i ; $(MAKE) install ) ; done
	@echo ; echo "Read the Catalog management guide chapter in the Catalog documentation "
	@echo "at http://www.senga.org/Catalog/current/doc/catalog_toc.html"
	@echo "Go to the URL http://www.mymachine.org/Catalog/ for the ready to use example."

';
}

WriteMakefile(
  'VERSION_FROM' => 'lib/Catalog.pm',
  'NAME'	 => 'Catalog',
  'DIR'          => [ split(" ", $subdirs) ],
  'PL_FILES'     => { map {("bin/$_.PL" => "bin/$_")} @programs_to_install },
  'EXE_FILES'    => [ map {"bin/$_"} @programs_to_install ],
  'MAN1PODS'     => { 'doc/Catalog.pod' => 'blib/man1/Catalog.1' },
  'dist'         => { COMPRESS => 'gzip', SUFFIX => '.gz' },
  'clean'	 => { FILES => '$(EXE_FILES)' },
);

