package Bundle::Catalog;

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

1;

__END__

=head1 NAME

Bundle::Catalog - A bundle to install all Catalog related modules

=head1 SYNOPSIS

 perl -MCPAN -e 'install Bundle::Catalog'

=head1 CONTENTS

DBI 1.02             - Database independent interface for Perl

DBD::mysql 2.0210    - mysql drivers for the Perl Database Interface (DBI)

MD5 1.7		     - Perl interface to the MD5 Message-Digest Algorithm

CGI 2.46	     - Simple Common Gateway Interface Class

XML::Parser 2.22     - parsing XML documents

XML::DOM 1.19	     - building DOM Level 1 compliant document structures

MIME::Base64 2.11    - Encoding and decoding of base64 strings

Unicode::String 1.21 - String of Unicode characters

Unicode::Map8 0.06   - Mapping table between 8-bit chars and Unicode

Catalog 0.05         - Resources catalog management and display

=head1 DESCRIPTION

This bundle defines all reqreq modules for Catalog.


=head1 AUTHOR

Loic Dachary <loic@senga.org>

=cut
