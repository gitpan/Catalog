#
#   Copyright (C) 1997, 1998
#   	Free Software Foundation, Inc.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
# $Header: /spare2/ecila-cvsroot/Catalog/lib/Catalog/dmoz.pm,v 1.4 1999/04/14 11:29:47 ecila40 Exp $
#
package Catalog::dmoz;

use strict;
use vars qw(@ISA %schema @tablelist_theme);

use Catalog;

@ISA = qw(Catalog);

@tablelist_theme = qw(catalog_related catalog_newsgroup);

%schema = (
		    'catalog_related' => "
create table catalog_related_NAME (
  #
  # Rowid of father
  #
  up int not null,
  #
  # Rowid of child
  #
  down int not null,

  index catalog_related_NAME1 (up),
  index catalog_related_NAME2 (down)
)
",
		    'catalog_newsgroup' => "
create table catalog_newsgroup_NAME (
  #
  # Table management information 
  #
  rowid int auto_increment not null,
  created datetime not null,
  modified timestamp not null,

  #
  # Rowid of father
  #
  category int not null,
  #
  # Rowid of child
  #
  url varchar(255) not null,

  unique catalog_newsgroup_NAME1 (rowid),
  index catalog_newsgroup_NAME2 (category),
  index catalog_newsgroup_NAME3 (url)
)
",
	   );
sub cimport_api {
    my($self, $name, $file) = @_;

    my($file_content) = $file;
    my($file_structure) = $file;
    $file_structure =~ s/content.rdf$/structure.rdf/o;
    my($converted) = $file;
    $converted =~ s/content.rdf$/dmoz.rdf/o;
    system("convert_dmoz $file_content $file_structure $converted");

    my($external) = Catalog::dmoz::external->new();
    $external->load($self, $name, $converted);

    unlink($converted) or error("cannot remove $converted : $!");
}

sub cbuild_theme {
    my($self, $name, $rowid) = @_;

    my($ret) = $self->SUPER::cbuild_theme($name, $rowid);

    #
    # Create catalog tables
    #
    my($table);
    foreach $table (@tablelist_theme) {
	my($schema) = $schema{$table};
	$schema =~ s/NAME/$name/g;
	$self->exec($schema);
    }

    return $ret;
}

sub cdestroy_real {
    my($self, $name) = @_;

    my($ret) = $self->SUPER::cdestroy_real($name);

    my($tables) = $self->tables();

    my($table);
    foreach $table (@tablelist_theme) {
	my($real) = "${table}_$name";
	if(grep(/^$real$/, @$tables)) {
	    $self->exec("drop table $real");
	}
    }
    
    return $ret;
}

#
# Implement specific actions when loading/unloading
#
package Catalog::dmoz::external;

use strict;
use vars qw(@ISA);

@ISA = qw(Catalog::external);

sub Related {
    my($self, $element) = @_;

    my($record) = $self->torecord($element);
    
    my($catalog) = $self->{'catalog'};
    my($name) = $self->{'name'};

    $catalog->insert("catalog_related_$name",
		     %$record);
}

sub Newsgroup {
    my($self, $element) = @_;

    my($record) = $self->torecord($element);
    
    my($catalog) = $self->{'catalog'};
    my($name) = $self->{'name'};

    $catalog->insert("catalog_newsgroup_$name",
		     %$record);
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
