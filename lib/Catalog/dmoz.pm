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
# $Header: /spare2/ecila-cvsroot/Catalog/lib/Catalog/dmoz.pm,v 1.5 1999/05/15 14:20:48 ecila40 Exp $
#
package Catalog::dmoz;

use strict;
use vars qw(@ISA @tablelist_theme %default_templates $head);

use Catalog;
use Catalog::tools::tools;

@ISA = qw(Catalog);

@tablelist_theme = qw(catalog_related catalog_newsgroup);

$head = "
<body bgcolor=#ffffff>
";

#
# Built in templates
#
%default_templates
    = (
       'cimport.html' => template_parse('inline cimport', "$head
<title>Load a DMOZ catalog</title>

<center><h1>Load a DMOZ catalog</h1></center>

<center><h3><font color=red>_COMMENT_</font></h3></center>

Follow the instructions below to build your own DMOZ catalog. Load and conversion will take a long time
(approximately 7 hours total). While the process is running, it sends white space characters to your
navigator to prevent time out. Do not close your navigator until the operation is complete or the
process will abort.

<p>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=context value=cimport_dmoz>
<ul>
<li> Load files content.rdf.gz and structure.rdf.gz from <a href=http://dmoz.org/rdf.html>http://dmoz.org/rdf.html</a>
and make sure they are in the same directory.
<li> Uncompress content.rdf.gz and structure.rdf.gz.
<li> Enter the absolute path of the directory containing content.rdf and structure.rdf <br>
<input type=text name=path size=50 value=_PATH_>
<p>
<li> Now you have two choices:
 <ul> 
 <li> <input type=submit name=action value='Convert it!'> Convert the content.rdf and structure.rdf file into a dmoz.rdf file suitable for
loading into Catalog 
 <li> <input type=submit name=action value='Load it!'> If the dmoz.rdf file exists, build a catalog from it.
 </ul>
</ul>
</form>
"),
);

sub initialize {
    my($self) = @_;

    $self->SUPER::initialize();

    my($templates) = $self->{'templates'};
    %$templates = ( %$templates, %default_templates );

    my($db) = $self->{'db'};
    $db->resources_load('dmoz_schema', 'Catalog::dmoz::schema');
}

#
# HTML massage dmoz files and load
#
sub cimport_dmoz {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($path) = $cgi->param('path');
    my($convert) = $cgi->param('action') =~ /convert/i ? 'convert' : 'load';

    $self->cerror("The path was not specified") if(!defined($path));

    $self->cimport_dmoz_api($path, $convert);

    if($convert eq 'convert') {
	return $self->cimport(Catalog::tools::cgi->new({
	    'context' => 'cimport',
	    'path' => $path,
	    'comment' => "The dmoz catalog was converted"
	    }));
    } elsif($convert eq 'load') {
	return $self->ccontrol_panel(Catalog::tools::cgi->new({
	    'context' => 'ccontrol_panel',
	    'comment' => "The dmoz catalog was (re)loaded"
	    }));
    }
}

sub cimport_dmoz_api {
    my($self, $path, $action) = @_;

    if($action eq 'convert') {
	my($file);
	foreach $file (qw(content.rdf structure.rdf)) {
	    $self->cerror("The $file file is missing or not readable in $path ") if(! -r "$path/$file");
	}
	$self->cerror("The $path directory is not writable, cannot create dmoz.rdf") if(! -w $path);
	system("convert_dmoz $path/content.rdf $path/structure.rdf $path/dmoz.rdf");
    } elsif($action eq 'load') {
	$self->cerror("The $path/dmoz.rdf file is missing or not readable in $path ") if(! -r "$path/dmoz.rdf");
	
	my($external) = Catalog::dmoz::external->new();
	$external->load($self, 'dmoz', "$path/dmoz.rdf");
    }
}

sub cbuild_theme {
    my($self, $name, $rowid) = @_;

    my($ret) = $self->SUPER::cbuild_theme($name, $rowid);

    #
    # Create catalog tables
    #
    my($table);
    foreach $table (@tablelist_theme) {
	my($schema) = $self->db()->schema('dmoz_schema', $table);
	$schema =~ s/NAME/$name/g;
	$self->db()->exec($schema);
    }

    return $ret;
}

sub cdestroy_real {
    my($self, $name) = @_;

    my($ret) = $self->SUPER::cdestroy_real($name);

    my($tables) = $self->db()->tables();

    my($table);
    foreach $table (@tablelist_theme) {
	my($real) = "${table}_$name";
	if(grep(/^$real$/, @$tables)) {
	    $self->db()->exec("drop table $real");
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

    $catalog->db()->insert("catalog_related_$name",
		     %$record);
}

sub Newsgroup {
    my($self, $element) = @_;

    my($record) = $self->torecord($element);
    
    my($catalog) = $self->{'catalog'};
    my($name) = $self->{'name'};

    $catalog->db()->insert("catalog_newsgroup_$name",
		     %$record);
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
