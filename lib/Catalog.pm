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
# 
# $Header: /spare2/ecila-cvsroot/Catalog/lib/Catalog.pm,v 1.35 1999/04/19 12:31:26 ecila40 Exp $
#
# 
package Catalog;
use vars qw(@ISA $head %default_templates %schema
	    @tablelist_theme @tablelist_alpha @tablelist_date
	    %datemap
	    $autoinc
	    $VERSION);
use strict;

use CGI;
use CGI::Carp;
use File::Path;
use File::Basename;
use MD5;
use Catalog::external;
use Catalog::tools::sqledit;
use Catalog::tools::tools;

@ISA = qw(Catalog::tools::sqledit);

$VERSION = "0.5";
sub Version { $VERSION; }

@tablelist_theme = qw(catalog_entry2category catalog_category catalog_category2category catalog_path);
@tablelist_alpha = qw(catalog_alpha);
@tablelist_date = qw(catalog_date);

%datemap = (
	     'french' => {
		 'days' => {
		     'Monday' => 'Lundi',
		     'Tuesday' => 'Mardi',
		     'Wednesday' => 'Mercredi',
		     'Thursday' => 'Jeudi',
		     'Friday' => 'Vendredi',
		     'Saturday' => 'Samedi',
		     'Sunday' => 'Dimanche',
		 },
		 'months' => {
		     'January' => 'Janvier',
		     'February' => 'F&eacute;vrier',
		     'March' => 'Mars',
		     'April' => 'Avril',
		     'May' => 'Mai',
		     'June' => 'Juin',
		     'July' => 'Juillet',
		     'August' => 'Ao&ucric;t',
		     'September' => 'Septembre',
		     'October' => 'Octobre',
		     'November' => 'Novembre',
		     'December' => 'Decembre',
		 },
	     },
	     );
$head = "
<body bgcolor=#ffffff>
";

%default_templates
    = (
       'error.html' => template_parse('inline error',
"$head
<title>Error message</title>

<center>
<h3>_MESSAGE_</h3>
</center>
"),
       'calpha_root.html' => template_parse('inline calpha_root',
"$head
<title>Alphabetical Navigation</title>

<h3>Alphabetical Navigation</h3>

_A_ _B_ _C_ _D_ _E_ _F_ _G_ _H_ _I_ _J_ _K_ _L_ <p>
_M_ _N_ _O_ _P_ _Q_ _R_ _S_ _T_ _U_ _V_ _W_ _X_ <p>
_Y_ _Z_ _0_ _1_ _2_ _3_ _4_ _5_ _6_ _7_ _8_ _9_ <p>
"),
       'calpha.html' => template_parse('inline calpha',
"$head
<title>Alphabetical Navigation _LETTER_</title>

<h3>Alphabetical Navigation _LETTER_</h3>

<table border=1>
<!-- start entry -->
<tr>_DEFAULTROW_</tr>
<!-- end entry --> 
</table>

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->

"),
       'csetup.html' => template_parse('inline csetup',
"$head
<center>
<h3>The catalog has not been setup</h3>
<p>
Shall I set it up for you ? It will create a table named <b>catalog</b>.
<p>
<form>
<input type=hidden name=context value=csetup_confirm>
<input type=submit value='Yes, setup a catalog'>
</form>

</center>
"),
       'ccontrol_panel.html' => template_parse('inline ccontrol_panel',
"$head
<title>Catalog control panel</title>

<center><h3>Catalog control panel</h3></center>

<center><h3><font color=red>_COMMENT_</font></h3></center>
<table border=1>
<tr><td colspan=2 align=middle><b>Configuration files</b></td></tr>
<tr><td>MySQL</td><td><a href=_SCRIPT_?context=confedit&file=mysql.conf>edit</a></td></tr>
<tr><td>CGI</td><td><a href=_SCRIPT_?context=confedit&file=cgi.conf>edit</a></td></tr>
<tr><td>Catalog</td><td><a href=_SCRIPT_?context=confedit&file=catalog.conf>edit</a></td></tr>
<tr><td>sqledit</td><td><a href=_SCRIPT_?context=confedit&file=sqledit.conf>edit</a></td></tr>
</table>
<p>
<table border=1>
<tr><td colspan=5 align=middle><b>Existing catalogs</b></td></tr>
<!-- start catalogs -->
<tr>
 <td><b><a href=_SCRIPT_?context=ccatalog_edit&name=_NAME_>_NAME_</a></b></td>
 <td><a href=_SCRIPT_?context=cbrowse&name=_NAME__ID_>browse</a></td>
 <td><a href=_SCRIPT_?context=_COUNT_&name=_NAME_>count</a></td>
 <td><a href=_SCRIPT_?context=cdestroy&name=_NAME_>destroy</a></td>
 <!-- start theme -->
 <td><a href=_SCRIPT_?context=cedit&name=_NAME__ID_>edit</a></td>
 <td><a href=_SCRIPT_?context=cdump&name=_NAME_>dump</a></td>
 <td><a href=_SCRIPT_?context=cimport&name=_NAME_>load</a></td>
 <td><a href=_SCRIPT_?context=cexport&name=_NAME_>unload</a></td>
 <!-- end theme -->
</tr>
<!-- end catalogs -->
</table>
<p>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=context value=cbuild>
Create _NAVIGATION_ catalog on table _TABLES_
<input type=submit value='Create it!'>
</form>
<p>
<table><tr><td>
<a href=_SCRIPT_?context=cimport>Load from file</a><br>
<a href=_SCRIPT_/>Simplified browsing</a><br>
<a href=_SCRIPT_?context=ccontrol_panel>Redisplay control panel</a><br>
<a href=_SCRIPT_?context=cdemo>Create a demo table (urldemo)</a><br>
</td><td>
<a href=_HTMLPATH_/catalog_toc.html><img src=_HTMLPATH_/images/help.gif alt=Help border=0 align=middle></a>
</td></tr></table>
<pre></b><i>
<font size=-1>
Catalog-$VERSION <a href=http://www.senga.org/>http://www.senga.org</a>
Copyright 1998, 1999 Free Software Foundation, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License , or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, write to the Free Software
    Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
</font>
</i></pre>
"),
       'csearch.html' => template_parse('inline csearch',
"$head
<title>Search results for _TEXT_</title>

<center>
<form action=_SCRIPT_ method=POST>
_HIDDEN_
<input type=text size=40 name=text value='_TEXT-QUOTED_'>
<input type=submit value='search'><br>
_WHAT-MENU_
</form>
</center>
<!-- start categories -->
<center>Categories matching <b>_TEXT_</b> (_COUNT_)</center>
<ul>
<!-- start entry -->
<li> <a href=_URL_>_PATHNAME_</a>
<!-- end entry -->
</ul>

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
<!-- end categories -->
<!-- start nocategories -->
<center>No category matches the search criterion</center>
<!-- end nocategories -->

<!-- start records -->

<center>Records matching <b>_TEXT_</b> (_COUNT_)</center>

<table border=1>
<!-- start entry -->

<!-- start category -->
<tr><td colspan=20><a href=_URL_>_PATHNAME_</a></td></tr>
<!-- end category -->

<tr>_DEFAULTROW_</tr>
<!-- end entry --> 
</table>

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
<!-- end records -->
<!-- start norecords -->
<center>No record matches the search criterion</center>
<!-- end norecords -->

"),
       'cedit.html' => template_parse('inline cedit',
"$head
<title>Edit category _CATEGORY_</title>

<center><h3><font color=red>_COMMENT_</font></h3></center>

<center>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=name value=_NAME_>
<input type=hidden name=context value=csearch>
<input type=hidden name=mode value=_CONTEXT_>
<input type=text size=40 name=text value='_TEXT-QUOTED_'>
<input type=submit value='search'><br>
</form>
</center>

<h3>Edit category _CATEGORY_</h3> 
<a href='_CENTRYINSERT_'><img src=_HTMLPATH_/images/new.gif alt='Insert a new record and link it to this category' border=0></a>
<a href='_CENTRYSELECT_'><img src=_HTMLPATH_/images/link.gif alt='Link an existing record to this category' border=0></a>
<a href='_CATEGORYINSERT_'><img src=_HTMLPATH_/images/open.gif alt='Create a sub category' border=0></a>
<a href='_CATEGORYSYMLINK_'><img src=_HTMLPATH_/images/plus.gif alt='Create a symbolic link to another category' border=0></a>
<a href='_CONTROLPANEL_'><img src=_HTMLPATH_/images/control.gif alt='Control panel' border=0></a>
<p>
<p>
_PATH_
<p>

<!-- start categories -->
<h3>Sub categories</h3>
<table>
<!-- params 'style' => 'table', 'columns' => 2 -->
<!-- start row --> 
<tr>
<!-- start entry -->
<td> _LINKS_ <a href='_URL_'>_NAME_</a> (_COUNT_) </td>
<!-- end entry -->
</tr>
<!-- end row --> 
</table>
<!-- end categories -->
<p>

<h3>Records in this category</h3>
<!-- start entry -->
<table border=1><tr><td>_LINKS_</td> _DEFAULTROW_</tr></table>
<p>
<!-- end entry -->

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
"),
       'catalog_category_select.html' => template_parse('inline catalog_category_select',
"$head
<title>Select category _CATEGORY_</title>

<h3>Select category _CATEGORY_</h3> 
_PATH_
<!-- start symlink -->
<a href='_CATEGORYSYMLINK_'><img src=_HTMLPATH_/images/select.gif alt='Select this category as a symbolic link' border=0></a>
<!-- end symlink -->
<p>

<!-- start categories -->
<h3>Sub categories</h3>
<table>
<!-- params 'style' => 'table', 'columns' => 2 -->
<!-- start row --> 
<tr>
<!-- start entry -->
<td> <a href='_URL_'>_NAME_</a> (_COUNT_) </td>
<!-- end entry -->
</tr>
<!-- end row --> 
</table>
<!-- end categories -->
<p>
"),
       'centryremove_all.html' => template_parse('inline centryremove_all', "$head
<body bgcolor=#ffffff>

<center>

<h3>Confirm removal of record from  _TABLE_</h3>

<form action=_SCRIPT_ method=POST>
<input type=submit name=remove value=remove>
_HIDDEN_
</form>

</center>
"),
       'cbrowse_root.html' => template_parse('inline cbrowse_root',
"$head
<title>Root</title>

<center>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=name value=_NAME_>
<input type=hidden name=context value=csearch>
<input type=hidden name=mode value=_CONTEXT_>
<input type=text size=40 name=text value='_TEXT-QUOTED_'>
<input type=submit value='search'><br>
</form>
</center>

<h3>Root</h3>

<!-- start categories -->
<h3>Sub categories</h3>
<ul>
<!-- start entry -->
<li> <a href='_URL_'>_NAME_</a> (_COUNT_)
<!-- end entry -->
</ul>
<!-- end categories -->
<p>
<!-- start entry -->
<p> <table border=1><tr>_DEFAULTROW_<tr></table>
<!-- end entry -->

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
"),
       'cbrowse.html' => template_parse('inline cbrowse',
"$head
<title>_CATEGORY_</title>

<center>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=name value=_NAME_>
<input type=hidden name=context value=csearch>
<input type=hidden name=mode value=_CONTEXT_>
<input type=text size=40 name=text value='_TEXT-QUOTED_'>
<input type=submit value='search'><br>
</form>
</center>

<h3>_CATEGORY_</h3>
<p>
_PATH_
<p>

<!-- start categories -->
<h3>Sub categories</h3>
<ul>
<!-- start entry -->
<li> <a href='_URL_'>_NAME_</a> (_COUNT_)
<!-- end entry -->
</ul>
<!-- end categories -->
<p>
<!-- start entry -->
<p> <table border=1><tr>_DEFAULTROW_<tr></table>
<!-- end entry -->

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
"),
       'cdestroy.html' => template_parse('inline cdestroy', "$head
<body bgcolor=#ffffff>

<center>

<h3>Confirm removal of catalog _NAME_</h3>

<form action=_SCRIPT_ method=POST>
<input type=submit name=remove value=remove>
_HIDDEN_
</form>

</center>
"),
       'edit.html' => template_parse('inline catalog edit', "$head
<html>
<body bgcolor=#ffffff>
<title>Edit _FILE_</title>
<center><a href=_SCRIPT_?context=ccontrol_panel>Back to Catalog Control Panel</a></center>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=context value=confedit>
<input type=hidden name=file value=_FILE_>
<input type=hidden name=rows value=_ROWS_>
<input type=hidden name=cols value=_COLS_>
<textarea name=text cols=_COLS_ rows=_ROWS_>_TEXT_</textarea>
<p>
<center>
<input type=submit name=action value=save>
<input type=submit name=action value=refresh>
</center>
<p>
_COMMENT_
</form>
</html>
"),
       'cdate_default.html' => template_parse('inline catalog cdate_default', "$head
<html>
<body bgcolor=#ffffff>
<title>Date catalog</title>
<!-- start years -->
  <a href=_YEARLINK_>_YEARFORMATED_</a> (_COUNT_)

  <blockquote>
  <!-- start months -->
    <!-- params format => '%M' -->
    <a href=_MONTHLINK_>_MONTHFORMATED_</a> (_COUNT_)

    <ul>
    <!-- start days -->
      <!-- params format => '%W, %d' -->
      <li> <a href=_DAYLINK_>_DAYFORMATED_</a> (_COUNT_)
    <!-- end days -->
    </ul>

  <!-- end months -->
  </blockquote>

<!-- end years -->

<!-- start records -->
Records
<!-- start entry -->
<p> <table border=1><tr>_DEFAULTROW_<tr></table>
<!-- end entry -->

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->

<!-- end records -->
</html>
"),
       'catalog_category_insert.html' => template_parse('inline catalog_category_insert', "$head
<title>Create a sub category</title>

<h3>Create a sub category</h3>
<form action=_SCRIPT_ method=POST>
_HIDDEN_
<table>
<tr><td><b>Category name*</b></td><td><input type=text name=name></td></tr>
</table>
<input type=submit value='Create it!'>
</form>
"),
       'catalog_category_edit.html' => template_parse('inline catalog_category_edit', "$head
<title>Edit category _NAME_</title>

<h3>Edit category _NAME_</h3>
<form action=_SCRIPT_ method=POST>
<input type=submit name=update value=update>
_HIDDEN_
<table>
<tr><td><b>Category name*</b></td><td><input type=text name=name value='_NAME-QUOTED_'></td></tr>
<tr><td><b>Total records</b></td><td>_COUNT_</td></tr>
<tr><td><b>Rowid</b></td><td>_ROWID_</td></tr>
<tr><td><b>Created</b></td><td>_CREATED_</td></tr>
<tr><td><b>Last modified</b></td><td>_MODIFIED_</td></tr>
</table>
</form>
"),
       'catalog_theme_insert.html' => template_parse('inline catalog_theme_insert', "$head
<title>Create _NAVIGATION_ catalog on table _TABLENAME_</title>

<h3>Create _NAVIGATION_ catalog on table _TABLENAME_</h3>

<form action=_SCRIPT_ method=POST>
_HIDDEN_
<input type=hidden name=tablename value=_TABLENAME_>
<input type=hidden name=navigation value=_NAVIGATION_>
<table>
<tr><td><b>Catalog name*</b></td><td><input type=text name=name></td></tr>
<tr><td><b>ORDER BY</b></td><td><input type=text name=corder size=60></td></tr>
<tr><td><b>WHERE</b></td><td><input type=text name=cwhere size=60></td></tr>
<tr><td><b>Dump path</b></td><td><input type=text name=dump size=60></td></tr>
<tr><td><b>Dump location</b></td><td><input type=text name=dumplocation size=60></td></tr>
<tr><td><b>Options</b></td><td>_INFO-CHECKBOX_</td></tr>
</table>
<input type=submit value='Create it!'>

</form>
"),
       'catalog_theme_edit.html' => template_parse('inline catalog_theme_edit', "$head
<title>Edit _NAVIGATION_ catalog _NAME_</title>
<h3>Edit _NAVIGATION_ catalog _NAME_</h3>

_EDITCOMMENT_
<form action=_SCRIPT_ method=POST>
<input type=submit name=update value=update>
_HIDDEN_
<table>
<tr><td><b>Table name</b></td><td>_TABLENAME_</td></tr>
<tr><td><b>ORDER BY</b></td><td><input type=text name=corder size=60 value='_CORDER-QUOTED_'></td></tr>
<tr><td><b>WHERE</b></td><td><input type=text name=cwhere size=60 value='_CWHERE-QUOTED_'></td></tr>
<tr><td><b>Dump path</b></td><td><input type=text name=dump size=60 value='_DUMP-QUOTED_'></td></tr>
<tr><td><b>Dump location</b></td><td><input type=text name=dumplocation size=60 value='_DUMPLOCATION-QUOTED_'></td></tr>
<tr><td><b>Options</b></td><td>_INFO-CHECKBOX_</td></tr>
<tr><td><b>Created</b></td><td>_CREATED_</td></tr>
<tr><td><b>Last modified</b></td><td>_MODIFIED_</td></tr>
</table>
</form>
"),
       'catalog_alpha_insert.html' => template_parse('inline catalog_alpha_insert', "$head
<title>Create _NAVIGATION_ catalog on table _TABLENAME_</title>

<h3>Create _NAVIGATION_ catalog on table _TABLENAME_</h3>

<form action=_SCRIPT_ method=POST>
_HIDDEN_
<input type=hidden name=tablename value=_TABLENAME_>
<input type=hidden name=navigation value=_NAVIGATION_>
<table>
<tr><td><b>Catalog name*</b></td><td><input type=text name=name></td></tr>
<tr><td><b>Field name*</b></td><td><input type=text name=fieldname></td></tr>
<tr><td><b>ORDER BY</b></td><td><input type=text name=corder size=60></td></tr>
<tr><td><b>WHERE</b></td><td><input type=text name=cwhere size=60></td></tr>
<tr><td><b>Options</b></td><td>_INFO-CHECKBOX_</td></tr>
</table>
<input type=submit value='Create it!'>

</form>
"),
       'catalog_alpha_edit.html' => template_parse('inline catalog_alpha_edit', "$head
<title>Edit _NAVIGATION_ catalog _NAME_</title>
<h3>Edit _NAVIGATION_ catalog _NAME_</h3>

_EDITCOMMENT_
<form action=_SCRIPT_ method=POST>
<input type=submit name=update value=update>
_HIDDEN_
<table>
<tr><td><b>Table name</b></td><td>_TABLENAME_</td></tr>
<tr><td><b>Field name</b></td><td><input type=text name=fieldname value='_FIELDNAME_'></td></tr>
<tr><td><b>ORDER BY</b></td><td><input type=text name=corder size=60 value='_CORDER-QUOTED_'></td></tr>
<tr><td><b>WHERE</b></td><td><input type=text name=cwhere size=60 value='_CWHERE-QUOTED_'></td></tr>
<tr><td><b>Options</b></td><td>_INFO-CHECKBOX_</td></tr>
<tr><td><b>Last cache update</b></td><td><input type=text name=updated value='_UPDATED_'</td></tr>
<tr><td><b>Created</b></td><td>_CREATED_</td></tr>
<tr><td><b>Last modified</b></td><td>_MODIFIED_</td></tr>
</table>
</form>
"),
       'catalog_date_insert.html' => template_parse('inline catalog_date_insert', "$head
<title>Create _NAVIGATION_ catalog on table _TABLENAME_</title>

<h3>Create _NAVIGATION_ catalog on table _TABLENAME_</h3>

<form action=_SCRIPT_ method=POST>
_HIDDEN_
<input type=hidden name=tablename value=_TABLENAME_>
<input type=hidden name=navigation value=_NAVIGATION_>
<table>
<tr><td><b>Catalog name*</b></td><td><input type=text name=name></td></tr>
<tr><td><b>Field name*</b></td><td><input type=text name=fieldname></td></tr>
<tr><td><b>ORDER BY</b></td><td><input type=text name=corder size=60></td></tr>
<tr><td><b>WHERE</b></td><td><input type=text name=cwhere size=60></td></tr>
<tr><td><b>Options</b></td><td>_INFO-CHECKBOX_</td></tr>
</table>
<input type=submit value='Create it!'>

</form>
"),
       'catalog_date_edit.html' => template_parse('inline catalog_date_edit', "$head
<title>Edit _NAVIGATION_ catalog _NAME_</title>
<h3>Edit _NAVIGATION_ catalog _NAME_</h3>

_EDITCOMMENT_
<form action=_SCRIPT_ method=POST>
<input type=submit name=update value=update>
_HIDDEN_
<table>
<tr><td><b>Table name</b></td><td>_TABLENAME_</td></tr>
<tr><td><b>Field name</b></td><td><input type=text name=fieldname value='_FIELDNAME_'></td></tr>
<tr><td><b>ORDER BY</b></td><td><input type=text name=corder size=60 value='_CORDER-QUOTED_'></td></tr>
<tr><td><b>WHERE</b></td><td><input type=text name=cwhere size=60 value='_CWHERE-QUOTED_'></td></tr>
<tr><td><b>Options</b></td><td>_INFO-CHECKBOX_</td></tr>
<tr><td><b>Last cache update</b></td><td><input type=text name=updated value='_UPDATED_'</td></tr>
<tr><td><b>Created</b></td><td>_CREATED_</td></tr>
<tr><td><b>Last modified</b></td><td>_MODIFIED_</td></tr>
</table>
</form>
"),
       'cdump.html' => template_parse('inline cdump', "$head
<title>Dump _NAME_ catalog in HTML</title>

<h3>Dump _NAME_ catalog in HTML</h3>

<center><h3><font color=red>Warning! All files and subdirectories of the specified path will first be removed.</font></h3></center>
<form action=_SCRIPT_ method=POST>
_HIDDEN_
<table>
<tr><td><b>Full path name*</b></td><td><input type=text name=path size=50 value='_PATH_'></td></tr>
<tr><td><b>Location*</b></td><td><input type=text name=location size=50 value='_LOCATION_'></td></tr>
</table>
<input type=submit value='Dump it!'>

</form>
"),
       'cimport.html' => template_parse('inline cimport', "$head
<title>Load a thematic catalog</title>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=context value=cimport_confirm>
<table>
<tr><td><b>Catalog name</b></td><td><input type=text name=name value=_NAME_></td></tr>
<tr><td><b>File path</b></td><td><input type=text name=file></td></tr>
</table>
<input type=submit value='Load it!'>
</form>
"),
       'cexport.html' => template_parse('inline cexport', "$head
<title>Unload a thematic catalog</title>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=context value=cexport_confirm>
<input type=hidden name=name value=_NAME_>
<table>
<tr><td><b>Catalog name</b></td><td>_NAME_</td></tr>
<tr><td><b>File path</b></td><td><input type=text name=file></td></tr>
</table>
<input type=submit value='Unload it!'>
</form>
"),
       );

#
# 3.21 reverse of 3.22 syntax :-(
#
if(exists($ENV{'MYSQL_OLD'})) {
    $autoinc = "not null auto_increment";
} else {
    $autoinc = "auto_increment not null";
}

%schema = (
		    'catalog' => "
create table catalog (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  #
  # Name of the catalog
  #
  name varchar(32) not null,
  #
  # Name of the table whose records are catalogued
  #
  tablename varchar(60) not null,
  #
  # Navigation scheme
  #
  navigation enum ('alpha', 'theme', 'date') default 'theme',
  #
  # State information
  #
  info set ('hideempty'),
  #
  # (alpha, date only) last update time
  #
  updated datetime,
  #
  # Order clause
  #
  corder varchar(128),
  #
  # Where clause
  #
  cwhere varchar(128),
  #
  # (alpha, date only) name of the field for sorting
  #
  fieldname varchar(60),
  #
  # (theme only) rowid of the root in catalog_category_<name>
  #
  root int not null,
  #
  # (theme only) full path name of the location to dump pages
  #
  dump varchar(255),
  #
  # (theme only) the location from which the dumped pages will be accessed
  #
  dumplocation varchar(255),

  unique catalog1 (rowid),
  unique catalog2 (name)
)
",
		    'catalog_auth' => "
create table catalog_auth (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  #
  # Yes if entry is usable
  #
  active enum ('yes', 'no') default 'no',
  #
  # login name of the editor
  #
  login char(16) not null,

  unique catalog_auth1 (rowid),
  unique catalog_auth2 (login)
)
",
		    'catalog_auth_properties' => "
create table catalog_auth_properties (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  #
  # Link to user descriptive entry (catalog_auth)
  #
  auth int not null,

  #
  # Authorization global to catalog
  #

  #
  # Allow everything
  #
  superuser char(1) not null default 'n',

  #
  # Authorization bound to a specific catalog
  #

  #
  # Name of the catalog on which this entry applies
  #
  catalogname varchar(32) not null,

  #
  # Allow everything on this catalog
  #
  catalogsuperuser char(1) not null default 'n',

  #
  # Authorization on a specific theme category
  #

  #
  # Link to the category (catalog_category_NAME) 
  #
  categorypointer int not null default 0,
  #
  # Allow sub category add/edit/remove
  #
  categorysubedit char(1) not null default 'n',
  #
  # Allow entries add/edit/remove
  #
  categoryentryedit char(1) not null default 'n',


  unique catalog_auth_categories1 (rowid),
  index catalog_auth_categories2 (auth),
  index catalog_auth_categories3 (catalogname),
  index catalog_auth_categories4 (categorypointer)
)
",
		    'catalog_entry2category' => "
create table catalog_entry2category_NAME (
  #
  # Table management information 
  #
  created datetime not null,
  modified timestamp not null,

  #
  # State information
  #
  info set ('hidden'),
  #
  # Rowid of the record from catalogued table
  #
  row int not null,
  #
  # Rowid of the category
  #
  category int not null,
  #
  # External identifier to synchronize with alien catalogs
  #
  externalid varchar(32) not null default '',

  index catalog_entry2category_NAME2 (created),
  index catalog_entry2category_NAME3 (modified),
  unique catalog_entry2category_NAME4 (row,category),
  index catalog_entry2category_NAME5 (category),
  index catalog_entry2category_NAME6 (externalid)
)
",
		    'catalog_category' => "
create table catalog_category_NAME (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  #
  # State information
  #
  info set ('root'),
  #
  # Full name of the category
  #
  name varchar(255) not null,
  #
  # Total number of records in this category and bellow
  #
  count int default 0,
  #
  # External identifier to synchronize with alien catalogs
  #
  externalid varchar(32) not null default '',

  unique catalog_category_NAME1 (rowid),
  index catalog_category_NAME2 (created),
  index catalog_category_NAME3 (modified),
  index catalog_category_NAME4 (name(122)),
  index catalog_category_NAME5 (externalid)
)
",
		    'catalog_path' => "
create table catalog_path_NAME (
  #
  # Full path name of the category
  #
  pathname text not null,
  #
  # MD5 key of the path name
  #
  md5 char(32) not null,
  #
  # Full path name translated to ids
  #
  path varchar(128) not null,
  #
  # Id of the last component
  #
  id int not null,

  unique catalog_path_NAME1 (md5),
  unique catalog_path_NAME2 (path),
  unique catalog_path_NAME3 (id)
)
",
		    'catalog_alpha' => "
create table catalog_alpha_NAME (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  #
  # The letter
  #
  letter char(1) not null,
  #
  # Count of records of the catalogued table have
  # a field starting with this letter.
  #
  count int default 0,

  unique catalog_alpha_NAME1 (rowid)
)
",
		    'catalog_date' => "
create table catalog_date_NAME (
  #
  # Table management information 
  #
  rowid int $autoinc,

  #
  # The date interval
  #
  tag char(8) not null,
  #
  # Count of records of the catalogued table have
  # a field starting with this letter.
  #
  count int default 0,

  unique catalog_date_NAME1 (rowid),
  unique catalog_date_NAME2 (tag)
)
",
		    'catalog_category2category' => "
create table catalog_category2category_NAME (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  #
  # State information
  #
  info set ('hidden', 'symlink'),
  #
  # Rowid of father
  #
  up int not null,
  #
  # Rowid of child
  #
  down int not null,
  #
  # External identifier to synchronize with alien catalogs
  #
  externalid varchar(32) not null default '',

  unique catalog_category2category_NAME1 (rowid),
  index catalog_category2category_NAME2 (created),
  index catalog_category2category_NAME3 (modified),
  unique catalog_category2category_NAME4 (up,down),
  index catalog_category2category_NAME5 (down),
  index catalog_category2category_NAME6 (externalid)
)
",
		    
		    );

sub initialize {
    my($self) = @_;

    $self->Catalog::tools::sqledit::initialize();

    my($config) = config_load("catalog.conf");
    %$self = (%$self, %$config) if(defined($config));

    my($encoding) = $self->{'encoding'} || '';
    $encoding = "ISO-8859-1";
    $self->{'encoding'} = $encoding;
    
    push(@{$self->{'params'}}, 'name', 'path');
    my($templates) = $self->{'templates'};
    %$templates = ( %$templates, %default_templates );
}

sub cinfo {
    my($self) = @_;

    if(!exists($self->{'ccatalog'})) {
	my($tables) = $self->tables();
	my($catalog) = grep(/^catalog$/, @$tables);
	if(defined($catalog)) {
	    $self->{'csetup'} = 'yes';
	    my($rows) = $self->exec_select("select rowid,name,tablename,navigation,info,fieldname,cwhere,corder,unix_timestamp(updated) as updated,root,dump,dumplocation from catalog");

	    if(@$rows) {
		$self->{'ccatalog'} = { map { $_->{'name'} => $_ } @$rows };
	    } else {
		$self->{'ccatalog'} = undef;
	    }
	    $self->{'ctables'} = [ grep(!/^catalog/, @$tables) ];
	}
    }

    return $self->{'ccatalog'};
}

sub cinfo_clear {
    my($self) = @_;

    delete($self->{'ccatalog'});
}

sub csetup {
    my($self) = @_;

    my($template) = $self->template("csetup");
    return $self->stemplate_build($template);
}

sub csetup_confirm {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    $self->csetup_api();

    return $self->ccontrol_panel(Catalog::tools::cgi->new({
	'context' => 'ccontrol_panel',
	'comment' => 'The catalog has been setup'
    }));
}

sub csetup_api {
    my($self) = @_;

    $self->exec($schema{'catalog'});
    $self->exec($schema{'catalog_auth'});
    $self->exec($schema{'catalog_auth_properties'});
    $self->cinfo_clear();
}

sub ccontrol_panel {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();
    
    my($url) = $cgi->url('-absolute' => 1);

    if(!defined($self->{'csetup'})) {
	return $self->csetup();
    }

    my($template) = $self->template("ccontrol_panel");

    my($template_catalogs) = $template->{'children'}->{'catalogs'};
    $self->serror("missing catalogs part") if(!defined($template_catalogs));
    my($template_theme) = $template_catalogs->{'children'}->{'theme'};

    if($ccatalog) {
	my($html) = '';
	my(%navigation2function) = (
				    'alpha' => 'calpha_count',
				    'theme' => 'category_count',
				    'date' => 'cdate_count',
				    );
	my($assoc) = $template_catalogs->{'assoc'};
	my($name, $catalog);
	while(($name, $catalog) = each(%$ccatalog)) {
	    my($root) = $catalog->{'root'};
	    my($navigation) = $catalog->{'navigation'};
	    my($count) =  $navigation2function{$navigation};
	    my($id) = '';
	    if($navigation eq 'theme') {
		$id = "&id=$root";
		my($assoc) = $template_theme->{'assoc'};
		template_set($assoc, '_ID_', $id);
		template_set($assoc, '_COUNT_', $count);
		template_set($assoc, '_NAME_', $name);
		template_set($assoc, '_SCRIPT_', $url);
	    } else {
		$template_theme->{'skip'} = 1;
	    }
	    template_set($assoc, '_ID_', $id);
	    template_set($assoc, '_COUNT_', $count);
	    template_set($assoc, '_NAME_', $name);
	    $html .= $self->stemplate_build($template_catalogs);
	}

	$template_catalogs->{'html'} = $html;
    } else {
	$template_catalogs->{'skip'} = 'yes';
    }
    my($navigation) = $cgi->popup_menu(-name => 'navigation',
				       -values => ['theme', 'alpha', 'date'],
				       -default => 'theme',
				       -labels => {
					   'theme' => 'Thematical',
					   'alpha' => 'Alphabetical',
					   'date' => 'Chronological',
					   });
    template_set($template->{'assoc'}, '_NAVIGATION_', $navigation);
    my($tables) = $cgi->popup_menu(-name => 'table',
				   -values => $self->{'ctables'});
    template_set($template->{'assoc'}, '_TABLES_', $tables);
    template_set($template->{'assoc'}, '_COMMENT_', $cgi->param('comment'));
    return $self->stemplate_build($template);
}

sub cimport {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($template) = $self->template("cimport");
    my($assoc) = $template->{'assoc'};

    template_set($assoc, '_NAME_', $cgi->param('name'));
    
    return $self->stemplate_build($template);
}

sub cimport_confirm {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    my($file) = $cgi->param('file');

    $self->serror("no file specified") if(!defined($file));
    $self->serror("$file is not a readable file") if(! -r $file);

    eval {
	$self->cimport_api($name, $file);
    };
    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->serror("load failed, check logs");
    }

    return $self->ccontrol_panel(Catalog::tools::cgi->new({
	'context' => 'ccontrol_panel',
	'comment' => "The $name catalog was (re)loaded"
    }));
}

sub cimport_api {
    my($self, $name, $file) = @_;

    my($external) = Catalog::external->new();
    $external->load($self, $name, $file);
}

sub cexport {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($template) = $self->template("cexport");
    my($assoc) = $template->{'assoc'};

    template_set($assoc, '_NAME_', $cgi->param('name'));
    
    return $self->stemplate_build($template);
}

sub cexport_confirm {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    my($file) = $cgi->param('file');

    $self->serror("no file specified") if(!defined($file));
    my($dir) = dirname($file);
    $self->serror("directory $dir is not writable") if(! -w $dir);

    eval {
	$self->cexport_api($name, $file);
    };
    
    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->serror("load failed, check logs");
    }

    return $self->ccontrol_panel(Catalog::tools::cgi->new({
	'context' => 'ccontrol_panel',
	'comment' => "The $name catalog was unloaded"
    }));
}

sub cexport_api {
    my($self, $name, $file) = @_;

    my($external) = Catalog::external->new();
    $external->unload($self, $name, $file);
}

sub cdemo {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    $self->cdemo_api();

    return $self->ccontrol_panel(Catalog::tools::cgi->new({'context' => 'ccontrol_panel'}));
}

sub cdemo_api {
    my($self) = @_;

    $self->serror("The urldemo table already exists") if($self->info_table("urldemo"));
    my($schema) = "
create table urldemo (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  info enum ('active', 'inactive') default 'active',
  url char(128),
  comment char(255),

  unique cdemo1 (rowid)
)
";
    $self->exec($schema);
}

sub categorysymlink {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    #
    # Show a form to create a new category symlink
    #
    my($rowid) = $cgi->param('rowid');
    my($name) = $cgi->param('name');
    my($root) = $ccatalog->{$name}->{'root'};
    if(!defined($rowid)) {
	my($params) = $self->params('context' => 'cedit',
				    'path' => undef,
				    'style' => 'catalog_category_select',
				    'id' => $root);
	eval {
	    $cgi = $cgi->fct_call($params,
				  'name' => 'select',
				  'args' => { },
				  'returned' => { },
				  );
	};
	if($@) {
	    my($error) = $@;
	    print STDERR $error;
	    $self->serror("recursive cgi call failed, check logs");
	}
	return $self->cedit($cgi);
    } else {
	my($name) = $cgi->param('name');
	$cgi = $cgi->fct_return('context' => 'cedit');
	#
	# Link the created category to its parent
	#
	$self->insert("catalog_category2category_$name",
		      'info' => 'hidden,symlink',
		      'up' => $cgi->param('id'),
		      'down' => $rowid);

	return $self->cedit($cgi);
    }
}

sub cdestroy {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    $self->cinfo();

    my($template) = $self->template('cdestroy');
    my($assoc) = $template->{'assoc'};

    template_set($assoc, '_NAME_', $cgi->param('name'));
    template_set($assoc, '_HIDDEN_', $self->hidden('context' => 'cdestroy_confirm'));

    return $self->stemplate_build($template);
}

sub cdestroy_confirm {
    my($self, $cgi) = @_;

    my($name) = $cgi->param('name');
    $self->cerror($cgi, "no catalog name specified") if(!defined($name));

    $self->cdestroy_api($name);

    return $self->ccontrol_panel(Catalog::tools::cgi->new({'context' => 'ccontrol_panel'}));
}

sub cdestroy_api {
    my($self, $name) = @_;

    my($ccatalog) = $self->cinfo();

    if(exists($ccatalog->{$name})) {
	$self->cdestroy_real($name);
    }
}

sub cdestroy_real {
    my($self, $name) = @_;

    my($tables) = $self->tables();

    my($table);
    foreach $table (@tablelist_theme, @tablelist_alpha, @tablelist_date) {
	my($real) = "${table}_$name";
	if(grep(/^$real$/, @$tables)) {
	    $self->exec("drop table $real");
	}
    }
    $self->exec("delete from catalog where name = '$name'");
    $self->cinfo_clear();
}

sub cedit {
    my($self, $cgi) = @_;

    my(%info) = ('mode' => 'cedit');

    return $self->cedit_1($cgi, \%info);
}

sub pathcheck {
    my($self, $name) = @_;
    my($table) = "catalog_path_$name";

    if(!$self->info_table($table)) {
	my($schema) = $schema{'catalog_path'};
	$schema =~ s/NAME/$name/g;
	$self->exec($schema);

	my($catalog) = $self->cinfo()->{$name};
	$self->insert($table,
		      'pathname' => '/',
		      'md5' => MD5->hexhash('/'),
		      'path' => ' ',
		      'id' => $catalog->{'root'});
	my($func) = sub {
	    my($id, $name, $pathname, $path) = @_;

	    $pathname = $self->path2url("/$pathname/");
	    $self->insert($table,
			  'pathname' => $pathname,
			  'md5' => MD5->hexhash($pathname),
			  'path' => ",$path,",
			  'id' => $id
			  );
	    $self->gauge();
	    return 1;
	};
	$self->walk_categories($name, $func);
	$self->cinfo_clear();
    }
}

sub pathcontext {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();
    my($pathname) = $cgi->param('pathname');
    my($params) = $self->{'pathcontext_params'};
    $cgi->reset_params($params);
    $cgi->param('page_length' => 1000000);
    my($name) = $cgi->param('name');
    $self->pathcheck($name);
    if(!defined($cgi->param('name'))) {
	$self->serror("missing name from pathcontext_params in catalog.conf");
    }
    if(!exists($ccatalog->{$name})) {
	$self->serror("the default catalog name, $name (from pathcontext_params in catalog.conf) is
not an existing catalog");
    }
    my($catalog) = $ccatalog->{$name};
    if($catalog->{'navigation'} ne 'theme') {
	$self->serror("pathcontext only valid for theme catalog");
    }

    my($md5) = MD5->hexhash($pathname);
    my($row) = $self->exec_select_one("select * from catalog_path_$name where md5 = '$md5'");
    #
    # If the path is not found, go to root of catalog
    #
    my($id) = defined($row) ? $row->{'id'} : $catalog->{'root'};
    
    $cgi->param('id', $id);
    $cgi->param('context', 'cbrowse');
    $cgi->param('path', $row->{'path'});
    $cgi->param('pathname', $pathname);
    my(%info) = ('mode' => 'cbrowse');
    return $self->cedit_1($cgi, \%info);
}

sub cbrowse {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($catalog) = $ccatalog->{$cgi->param('name')};

    if($catalog->{'navigation'} eq 'alpha') {
	return $self->calpha($cgi);
    } elsif($catalog->{'navigation'} eq 'date') {
	return $self->cdate($cgi);
    } else {
	my(%info) = ('mode' => 'cbrowse');
	return $self->cedit_1($cgi, \%info);
    } 

}

sub calpha {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($name) = $cgi->param('name');
    my($catalog) = $ccatalog->{$name};
    my($letter) = $cgi->param('letter');
    if(!defined($letter)) {
	my($base) = "calpha_root";
	my($template) = $self->template($base);
	my($assoc) = $template->{'assoc'};

	my($rows) = $self->exec_select("select letter,count from catalog_alpha_$name");
	$rows = { map { $_->{'letter'} => $_->{'count'} } @$rows };
	my($day) = 24 * 60 * 60;
	if(($catalog->{'updated'} || 0) < time() - $day) {
	    $self->calpha_count_1($rows, $catalog->{'tablename'}, $catalog->{'fieldname'});
	}
	my($url) = $self->ccall();
	my($tag);
	foreach $tag (keys(%$assoc)) {
	    my($what);
	    ($letter, $what) = $tag =~ /_(.)(URL|COUNT|LETTER)_/;
	    ($letter) = $tag =~ /_(.)_/ if(!defined($what));
	    if(defined($letter)) {
		$letter = lc($letter);
		if(exists($rows->{$letter})) {
		    if(defined($what) && $what eq 'URL') {
			$assoc->{$tag} = $self->ccall('letter' => ($rows->{$letter} > 0 ? $letter : 'none'));
		    } elsif(defined($what) && $what eq 'COUNT') {
			$assoc->{$tag} = $rows->{$letter};
		    } elsif(defined($what) && $what eq 'LETTER') {
			$assoc->{$tag} = $rows->{$letter} > 0 ? $letter : "${letter}0";
		    } else {
			my($count) = $rows->{$letter};
			my($html);
			if($count > 0) {
			    $html = "<a href='$url&letter=$letter'>$letter</a> ($count)";
			} else {
			    $html = $letter;
			}
			$assoc->{$tag} = $html;
		    }
		} else {
		    $assoc->{$tag} = '';
		}
	    }
	}
	
	return $self->stemplate_build($template);
    } else {
	$self->serror("no entries for this letter in $name") if($letter eq 'none');
	return $self->catalog_searcher("calpha", $catalog->{'tablename'}, { 'mode' => 'cbrowse'}, " $catalog->{'fieldname'} like '$letter\%' ", "letter");
	
    }
}

sub calpha_count {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');

    #
    # Force recalculation at first browsing action
    #
    $self->update("catalog", "name = '$name'",
		  'updated' => 0);
    return $self->ccontrol_panel(Catalog::tools::cgi->new({'context' => 'ccontrol_panel'}));
}

sub calpha_count_1 {
    my($self, $letters, $table, $field) = @_;
    my($cgi) = $self->{'cgi'};
    my($name) = $cgi->param('name');
    my($catalog) = $self->cinfo()->{$name};

    my($where) = $catalog->{'cwhere'};
    if(defined($where) && $where !~ /^\s*$/) {
	$where = "and ($where)";
    } else {
	$where = '';
    }

    my($letter);
    foreach $letter (keys(%$letters)) {
	my($count) = $self->exec_select_one("select count(*) as count from $table where $field like '$letter%' $where")->{'count'};
	$letters->{$letter} = $count;
	$self->update("catalog_alpha_$name", "letter = '$letter'",
		      'count' => $count);
    }
    $self->update("catalog", "name = '$name'",
		  'updated' => $self->datetime(time()));
}

sub cdate {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($name) = $cgi->param('name');
    my($catalog) = $ccatalog->{$name};

    my(%intervals) = $self->cdate_cgi2intervals($cgi);

    my($day) = 24 * 60 * 60;
    if((($catalog->{'updated'} || 0) < time() - $day) ||
       ($self->exec_select_one("select count(*) as count from catalog_date_$name")->{'count'} <= 0)) {
	$self->cdate_count_1($catalog->{'tablename'}, $catalog->{'fieldname'});
    }

    #
    # Try to load the most specific template first, then backup to
    # cdate_default if none is found.
    #
    my($prefix) = $cgi->param('template') ? "cdate_" . $cgi->param('template') : "cdate_default";
    my($template) = template_load("$prefix.html", $self->{'templates'}, $cgi->param('style'));
    if(!defined($template)) {
	$template = $self->template("cdate_default");
    }

    #
    # Format the index
    #
    if(exists($template->{'children'}->{'years'})) {
	$self->cdate_index($template->{'children'}->{'years'}, $intervals{'index'},
			   {
			       'complement' => '0101',
			       'length' => 4,
			       'format' => '%Y',
			       'order' => 'tag desc',
			       'tag_ftag' => 'YEARFORMATED',
			       'tag_link' => 'YEARLINK',
			       'tag_date' => 'YEARDATE',
			       'next_period' => 'months',
			       },
			   {
			       'complement' => '01',
			       'length' => 6,
			       'format' => '%M %Y',
			       'order' => 'tag desc',
			       'tag_ftag' => 'MONTHFORMATED',
			       'tag_link' => 'MONTHLINK',
			       'tag_date' => 'MONTHDATE',
			       'next_period' => 'days',
			       },
			   {
			       'complement' => '',
			       'length' => 8,
			       'format' => '%d %M %Y',
			       'tag_ftag' => 'DAYFORMATED',
			       'tag_link' => 'DAYLINK',
			       'tag_date' => 'DAYDATE',
			       'order' => 'tag desc',
			       });
    }

    #
    # Format the record list
    #
    if(exists($template->{'children'}->{'records'})) {
	$self->cdate_records($template->{'children'}->{'records'}, $intervals{'records'});
    }
    
    return $self->stemplate_build($template);
}

sub cdate_index {
    my($self, $template, $interval, $spec, @specs) = @_;

#    warn("from = $interval->{'from'} => to = $interval->{'to'}");
    my($cgi) = $self->{'cgi'};
    my($name) = $cgi->param('name');
    my($catalog) = $self->cinfo()->{$name};
    my($url) = $cgi->url('-absolute' => 1);

#    warn("cdate_index " . ostring($interval));

    $self->cdate_normalize($interval);

    my($length) = $spec->{'length'};
    my($format) = exists($template->{'params'}->{'format'}) ? $template->{'params'}->{'format'} : $spec->{'format'};
    my($order) = exists($template->{'params'}->{'order'}) ? $template->{'params'}->{'order'} : $spec->{'order'};
    my($language) = $template->{'params'}->{'language'};
#    warn($language);
    my($from) = substr($interval->{'from'}, 0, $length);
    my($to) = substr($interval->{'to'}, 0, $length);

    #
    # Recurse if template specified by user
    #
    my($next_period) = $spec->{'next_period'};
    if(defined($next_period) &&
       !exists($template->{'children'}->{$next_period})) {
	undef($next_period);
    }
    
    my($sql) = "select tag,date_format(concat(tag, '$spec->{'complement'}'), '$format') as ftag,count from catalog_date_$name where length(tag) = $length and tag $interval->{'from_op'} '$from' and tag $interval->{'to_op'} '$to' order by $order";
    my($rows) = $self->exec_select($sql);
#    warn($sql);

    my($assoc) = $template->{'assoc'};

    my($html) = '';
    my($row);
    foreach $row (@$rows) {
	my($ftag) = $row->{'ftag'};
	if($language) {
	    $ftag =~ s/(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)/$datemap{$language}{'days'}{$1}/g;
	    $ftag =~ s/(January|February|March|April|May|June|July|August|September|October|November|December)/$datemap{$language}{'months'}{$1}/g;
	}
	template_set($assoc, "_$spec->{'tag_ftag'}_", $ftag);
	template_set($assoc, "_$spec->{'tag_date'}_", $row->{'tag'});
	template_set($assoc, "_$spec->{'tag_link'}_", $self->ccall('date' => $row->{'tag'}));
	template_set($assoc, "_COUNT_", $row->{'count'});

	if(defined($next_period)) {
	    my($interval_new) = $self->cdate_intersection($self->cdate_normalize({ 'date' => $row->{'tag'} }), $interval);
	    $self->cdate_index($template->{'children'}->{$next_period},
			       $interval_new,
			       @specs);
	}

	$html .= $self->stemplate_build($template);
    }

    $template->{'html'} = $html;
}

sub cdate_records {
    my($self, $template, $interval) = @_;
    my($cgi) = $self->{'cgi'};
    my($name) = $cgi->param('name');
    my($catalog) = $self->cinfo()->{$name};
    my($url) = $cgi->url('-absolute' => 1);

    my($from) = $interval->{'from'};
    $from =~ s/^(\d\d\d\d)(\d\d)(\d\d)$/$1-$2-$3 00:00:00/;
    my($to) = $interval->{'to'};
    $to =~ s/^(\d\d\d\d)(\d\d)(\d\d)$/$1-$2-$3 23:59:59/;

    my($field) = $catalog->{'fieldname'};
    my($table) = $catalog->{'tablename'};
    my($where) = " ( $table.$field $interval->{'from_op'} '$from' and $table.$field $interval->{'to_op'} '$to' ) ";
    
    if(defined($catalog->{'cwhere'}) && $catalog->{'cwhere'} !~ /^\s*$/) {
	$where .= " and ($catalog->{'cwhere'})";
    }

#    warn($where);

    my(%context) = (
		    'context' => 'catalog entries',
		    'params' => [ 'from', 'to', 'date', 'index_from', 'index_to', 'index_date', 'records_from', 'records_to', 'records_date', 'template' ],
		    'url' => $cgi->url('-absolute' => 1),
		    'page' => scalar($cgi->param('page')),
		    'page_length' => scalar($cgi->param('page_length')),
		    'template' => $template,
		    'expand' => 'yes',
		    'table' => $table,
		    'where' => $where,
		    'order' => $catalog->{'corder'},
		    );

    return $self->searcher(\%context);
}

sub cdate_cgi2intervals {
    my($self, $cgi) = @_;

    my(%params) = (
		   'all' => {
		       'date' => scalar($cgi->param('date')),
		       'from' => scalar($cgi->param('from')),
		       'to' => scalar($cgi->param('to')),
		   },
		   'index' => {
		       'date' => scalar($cgi->param('index_date')),
		       'from' => scalar($cgi->param('index_from')),
		       'to' => scalar($cgi->param('index_to')),
		   },
		   'records' => {
		       'date' => scalar($cgi->param('records_date')),
		       'from' => scalar($cgi->param('records_from')),
		       'to' => scalar($cgi->param('records_to')),
		   },
		   );

    my(@params);
    if($cgi->param('date') ||
       $cgi->param('from') ||
       $cgi->param('to')) {
	push(@params, 'all');
    } else {
	push(@params, 'index', 'records');
    }

    #
    # Normalize arguments
    #
    my($param);
    foreach $param (@params) {
	$self->cdate_normalize($params{$param});
    }
    
    #
    # Expand so that index and records are filled
    #
    if($params[0] eq 'all') {
	$params{'index'} = $params{'records'} = $params{'all'};
    }

    return (
	     'index' => $params{'index'},
	     'records' => $params{'records'} );
}

sub cdate_normalize {
    my($self, $spec) = @_;

    return if(exists($spec->{'normalized'}));

    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    $mon++;

    if($year < 60) {
	$year += 2000;
    } else {
	$year += 1900;
    }

    my($now) = sprintf("$year%02d%02d", $mon, $mday);
    
    $spec->{'from_op'} = '>=';
    $spec->{'to_op'} = '<=';

    #
    # Fill from and to
    #
    if($spec->{'date'}) {
	#
	# A specific day
	#
	$spec->{'from'} = $spec->{'date'};
	$spec->{'to'} = $spec->{'date'};
    } else {
	if(!$spec->{'from'} && !$spec->{'to'}) {
	    #
	    # No date specified, default to all
	    #
	    $spec->{'from'} = "19700101";
	    $spec->{'to'} = $now;
	} elsif($spec->{'from'} && !$spec->{'to'}) {
	    #
	    # From a specified date in the paste up to now
	    #
	    $spec->{'to'} = $now;
	} elsif($spec->{'from'} && !$spec->{'to'}) {
	    #
	    # From the beginning of type up to the specified date
	    #
	    $spec->{'from'} = "19700101";
	} else {
	    #
	    # A specified interval time
	    #
	    ;
	}
    }

    #
    # Normalize date spec from 
    #
    if($spec->{'from'} =~ /^\d\d\d\d$/) {
	$spec->{'from'} .= "0101";
    } elsif($spec->{'from'} =~ /^\d\d\d\d\d\d$/) {
	$spec->{'from'} .= "01";
    }
    #
    # Normalize date spec to 
    #
    if($spec->{'to'} =~ /^\d\d\d\d$/) {
	$spec->{'to'} .= "1231";
    } elsif($spec->{'to'} =~ /^(\d\d\d\d)(\d\d)$/) {
	my($rows) = $self->exec_select("select date_format(date_sub(date_add('$1-$2-01', interval 1 month), interval 1 day), '%Y%m%d') as d");
	$spec->{'to'} = $rows->[0]->{'d'};
    }

    $spec->{'normalized'}++;

#    warn("cdate_normalize " . ostring($spec));

    return $spec;
}

sub cdate_intersection {
    my($self, $i1, $i2) = @_;

    return {
	'from' => ($i1->{'from'} > $i2->{'from'} ? $i1->{'from'} : $i2->{'from'}),
	'to' => ($i1->{'to'} < $i2->{'to'} ? $i1->{'to'} : $i2->{'to'}),
    };
}

#
# At the moment, strictly identical to calpha_count
#
sub cdate_count {
    return calpha_count(@_);
}

sub cdate_count_1 {
    my($self, $table, $field) = @_;
    my($cgi) = $self->{'cgi'};
    my($name) = $cgi->param('name');
    my($catalog) = $self->cinfo()->{$name};

    my($where) = $catalog->{'cwhere'};
    if(defined($where) && $where !~ /^\s*$/) {
	$where = "where $where";
    } else {
	$where = '';
    }

    $self->exec("delete from catalog_date_$name");

    $self->exec("insert into catalog_date_$name (tag, count) select date_format($field, '%Y') as yyyy, count(rowid) from $table $where group by yyyy order by yyyy");
    $self->exec("insert into catalog_date_$name (tag, count) select date_format($field, '%Y%m') as yyyymm, count(rowid) from $table $where group by yyyymm order by yyyymm");
    $self->exec("insert into catalog_date_$name (tag, count) select date_format($field, '%Y%m%d') as yyyymmdd, count(rowid) from $table $where group by yyyymmdd order by yyyymmdd");

    $self->update("catalog", "name = '$name'",
		  'updated' => $self->datetime(time()));
}

sub category_count {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    $self->category_count_api($name);
    return $self->ccontrol_panel(Catalog::tools::cgi->new({'context' => 'ccontrol_panel'}));
}

sub category_count_api {
    my($self, $name) = @_;

    my($catalog) = $self->cinfo()->{$name};
    my($where) = $catalog->{'cwhere'};
    if(defined($where) && $where !~ /^\s*$/) {
	$where = "and ($where)";
    } else {
	$where = '';
    }

    $self->update("catalog_category_$name", "",
		  'count' => 0);
    $self->category_count_1($name, $where, $catalog->{'tablename'}, $catalog->{'root'});
}

sub category_count_1 {
    my($self, $name, $where, $table, $id) = @_;

    my($count) = $self->exec_select_one("select count(*) from $table, catalog_entry2category_$name where ($table.rowid = catalog_entry2category_$name.row and catalog_entry2category_$name.category = $id) $where")->{'count(*)'};

    dbg("found $count entries at id $id", "catalog");

    my($rows) = $self->exec_select("select a.rowid from catalog_category_$name as a, catalog_category2category_$name as b where a.rowid = b.down and b.up = $id");
    my($row);
    foreach $row (@$rows) {
	$count += $self->category_count_1($name, $where, $table, $row->{'rowid'});
	$self->gauge();
    }

    $self->update("catalog_category_$name", "rowid = $id",
		  'count' => $count);
    
    return $count;
}

sub csearch {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($name) = $cgi->param('name');
    my($catalog) = $ccatalog->{$name};
    my($navigation) = $catalog->{'navigation'};

    $self->serror("%s catalog cannot be searched", $navigation) if($navigation ne 'theme');

    my($what) = $cgi->param('what');
    my($mode) = $cgi->param('mode') || 'cbrowse';

    my($select_category);
    $select_category = $self->csearch_param2select('categories') if(!defined($what) || $what eq 'categories' || $what eq '');
#    warn($select_category);
    my($select_records);
    $select_records = $self->csearch_param2select('records') if(!defined($what) || $what eq 'records' || $what eq '');
#    warn($select_records);

    my($template) = $self->template('csearch');
    my($results_count) = 0;
    #
    # Search in categories
    #
    my($template_categories) = $template->{'children'}->{'categories'};
    $self->serror("missing categories part") if(!defined($template_categories));
    my($template_nocategories) = $template->{'children'}->{'nocategories'};
    $self->serror("missing nocategories part") if(!defined($template_nocategories));
    if(defined($select_category)) {
	my($layout) = sub {
	    my($template, $subname, $result, $context) = @_;

	    my($assoc) = $template->{'assoc'};
	    my($row) = $result->{"catalog_category_$name"};
	    my(@result_key) = keys(%$row);
#	    warn("result_key = @result_key, $row->{'pathname'}");
	    
	    #
	    # Build forged tags
	    #
	    if(exists($assoc->{'_URL_'})) {
		my($url);
		if($mode eq 'pathcontext') {
		    my($pathname) = $row->{'pathname'};
		    $url = $cgi->url('-absolute' => 1) . $pathname;
		} else {
		    my($path) = $row->{'path'};
		    $path =~ s/^,(.*),$/$1/o;
		    $url = $self->ccall('context' => $mode,
					'id' => $row->{'rowid'},
					'path' => $path);
		}
		$assoc->{'_URL_'} = $url;
	    }

	    $result->{"catalog_path_$name"} = {
		'pathname' => $row->{'pathname'},
	    };
	    
	    $self->searcher_layout_result($template, $subname, $result, $context);
	};
	my(%context) = (
			'params' => [ 'text', 'what', 'mode' ],
			'url' => $cgi->url('-absolute' => 1),
			'page' => scalar($cgi->param('page')),
			'page_length' => scalar($cgi->param('page_length')),
			'context' => 'catalog search categories',
			'template' => $template_categories,
			'accept_empty' => 'yes',
			'layout' => $layout,
			'table' => "catalog_category_$name",
			'sql' => $select_category,
			);

	$results_count = $self->searcher(\%context);

	if($results_count <= 0) {
	    $template_categories->{'skip'} = 1;
	    #
	    # If searching in records, do not bark because nothing found,
	    # wait for records search to complete.
	    #
	    if(defined($select_records)) {
		$template_nocategories->{'skip'} = 1;
	    }
	} else {
	    $template_nocategories->{'skip'} = 1;
	    my($assoc) = $template_categories->{'assoc'};
	    template_set($assoc, '_COUNT_', $results_count);
	    template_set($assoc, '_TEXT_', $cgi->param('text'));
	    template_set($assoc, '_TEXT-QUOTED_', Catalog::tools::cgi::myescapeHTML($cgi->param('text')));

	}
    } else {
	$template_categories->{'skip'} = 1;
	$template_nocategories->{'skip'} = 1;
    }
    #
    # Search in records, if no category found
    #
    my($template_records) = $template->{'children'}->{'records'};
    $self->serror("missing records part") if(!defined($template_records));
    my($template_norecords) = $template->{'children'}->{'norecords'};
    $self->serror("missing norecords part") if(!defined($template_norecords));
    if($results_count <= 0 && defined($select_records)) {
	my($catalog) = $self->cinfo()->{$name};
	my($table) = $catalog->{'tablename'};
	my($current_pathname) = '';
	
	my($layout) = sub {
	    my($template, $subname, $result, $context) = @_;

	    my($assoc) = $template->{'assoc'};
	    my($row) = $result->{$table};
	    my(@result_key) = keys(%$row);
#	    warn("result_key = @result_key, $row->{'pathname'}");
	    
	    my($template_category) = $template->{'children'}->{'category'};
	    $self->serror("missing records/category part") if(!defined($template_category));
	    if($row->{'pathname'} ne $current_pathname) {
		$current_pathname = $row->{'pathname'};
		my($assoc) = $template_category->{'assoc'};
		#
		# Build forged tags
		#
		if(exists($assoc->{'_URL_'})) {
		    my($url);
		    if($mode eq 'pathcontext') {
			my($pathname) = $row->{'pathname'};
			$url = $cgi->url('-absolute' => 1) . $pathname;
		    } else {
			my($path) = $row->{'path'};
			$path =~ s/^,(.*),$/$1/o;
			$url = $self->ccall('context' => $mode,
					    'id' => $row->{'id'},
					    'path' => $path);
		    }
		    $assoc->{'_URL_'} = $url;
		}

		$self->row2assoc("catalog_path_$name", $row, $assoc);
		$template_category->{'skip'} = 0;
	    } else {
		$template_category->{'skip'} = 1;
	    }
	    
	    $self->searcher_layout_result($template, $subname, $result, $context);
	};
	my(%context) = (
			'params' => [ 'text', 'what', 'mode' ],
			'url' => $cgi->url('-absolute' => 1),
			'page' => scalar($cgi->param('page')),
			'page_length' => scalar($cgi->param('page_length')),
			'context' => 'catalog search records',
			'template' => $template_records,
			'accept_empty' => 'yes',
			'layout' => $layout,
			'table' => $table,
			'sql' => $select_records,
			);

	$results_count = $self->searcher(\%context);

	if($results_count <= 0) {
	    $template_records->{'skip'} = 1;
	} else {
	    $template_norecords->{'skip'} = 1;
	    my($assoc) = $template_records->{'assoc'};
	    template_set($assoc, '_COUNT_', $results_count);
	    template_set($assoc, '_TEXT_', $cgi->param('text'));
	    template_set($assoc, '_TEXT-QUOTED_', Catalog::tools::cgi::myescapeHTML($cgi->param('text')));

	}
    } else {
	$template_records->{'skip'} = 1;
	$template_norecords->{'skip'} = 1;
    }

    my($assoc) = $template->{'assoc'};
    template_set($assoc, '_HIDDEN_',
		 $self->hidden('mode' => scalar($cgi->param('mode')),
			       'boolean' => scalar($cgi->param('boolean')),
			       )),
    my($what_menu) = $cgi->popup_menu(-name => 'what',
				      -values => ['', 'categories', 'records'],
				      -default => '',
				      -labels => {
					  '' => 'All',
					  'categories' => 'Categories',
					  'records' => 'Records',
				      });
    template_set($assoc, '_WHAT-MENU_', $what_menu);
    template_set($assoc, '_COUNT_', $results_count);
    template_set($assoc, '_TEXT_', $cgi->param('text'));
    template_set($assoc, '_TEXT-QUOTED_', Catalog::tools::cgi::myescapeHTML($cgi->param('text')));
    return $self->stemplate_build($template);
}

sub string2words {
    my($self, $string) = @_;

    my(@words);
    if(!exists($self->{'encoding'}) ||
       $self->{'encoding'} =~ /^iso-latin/io ||
       $self->{'encoding'} =~ /^iso-8859/io) {
	while($string =~ /([a-z0-9\200-\376-]+)/oig) {
	    my($word) = lc($1);
	    $word =~ s/([a-z])/\[$1\u$1\]/g;
	    push(@words, $word);
	}
    } else {
	@words = split(' ', $string);
    }
    return @words;
}

sub csearch_param2select {
    my($self, $what) = @_;
    my($cgi) = $self->{'cgi'};
    my($name) = $cgi->param('name');
    my($boolean) = $cgi->param('boolean') || 'or';
    my($words) = $cgi->param('text');
    #
    # No search if nothing specified
    #
    return undef if(!defined($words) && $words =~ /^\s*$/o);

    my(@words) = $self->string2words($cgi->param('text'));
    #
    # No search if no words found
    #
    return undef if(!@words);

    if($what eq 'categories') {
	return $self->csearch_param2select_categories($name, $boolean, $words, @words);
    } else {
	return $self->csearch_param2select_records($name, $boolean, $words, @words);
    }
}

sub csearch_param2select_records {
    my($self, $name, $boolean, $words, @words) = @_;

    my($catalog) = $self->cinfo()->{$name};
    my($table) = $catalog->{'tablename'};
    my($table_info) = $self->info_table($table);
    my($primary_key) = $table_info->{'_primary_'};
    my($spec) = $self->{'search'}->{$name};

    my(@fields);
    if(defined($spec) && exists($spec->{'searched'})) {
	@fields = split(',', $spec->{'searched'});
	$self->serror("no searched fields specified in catalog.conf") if(!@fields);
    } else {
	my($field, $info);
	while(($field, $info) = each(%$table_info)) {
	    push(@fields, $field) if(ref($info) eq 'HASH' && $info->{'type'} eq 'char');
	}
	$self->serror("no char fields in $table") if(!@fields);
    }

    my($fields_extracted) = '';
    if(defined($spec) && exists($spec->{'extracted'})) {
	$fields_extracted = $spec->{'extracted'};
    } else {
	$fields_extracted = "$table.*";
    }
    $self->serror("no extracted fields for $table") if($fields_extracted =~ /^\s*$/);

    my($where) = '';
    my($field);
    foreach $field (@fields) {
	my($word);
	foreach $word (@words) {
	    if(exists($self->{'encoding'}) &&
	       $self->{'encoding'} =~ /^big5$/io) {
		$where .= "$field like '%$word%' $boolean ";
	    } else {
		
		$where .= "$field regexp '[[:<:]]" . $word . "[[:>:]]' $boolean ";
	    }
	}
    }
    $where =~ s/ $boolean $//;

    my($order) = '';
    if(defined($spec) && exists($spec->{'order'})) {
	$order = ", $spec->{'order'}";
    }

    my($select) = "select $fields_extracted,c.pathname,c.path,c.id from $table, catalog_entry2category_$name as b, catalog_path_$name as c where ( $where ) and $table.$primary_key = b.row and b.category = c.id order by c.pathname asc $order";

    return $select;
}

sub csearch_param2select_categories {
    my($self, $name, $boolean, $words, @words) = @_;

    my($where) = '';

    my($word);
    foreach $word (@words) {
	if(exists($self->{'encoding'}) && $self->{'encoding'} =~ /^big5$/io) {
	    $where .= "name like '%$word%' $boolean ";
	} else {
	    $where .= "name regexp '[[:<:]]" . $word . "[[:>:]]' $boolean ";
	}
    }
    $where =~ s/ $boolean $//;

    my($select) = "select a.rowid,a.name,a.info,b.path,b.pathname from catalog_category_$name as a,catalog_path_$name as b where a.rowid = b.id and ( $where ) ";

    return $select;
}

sub cdump {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($name) = $cgi->param('name');
    my($catalog) = $ccatalog->{$name};
    my($navigation) = $catalog->{'navigation'};
    $self->serror("%s catalog cannot be dumped", $navigation) if($navigation ne 'theme');

    my($template) = $self->template('cdump');
    my($assoc) = $template->{'assoc'};

    template_set($assoc, '_PATH_', Catalog::tools::cgi::myescapeHTML($catalog->{'dump'}));
    template_set($assoc, '_LOCATION_', Catalog::tools::cgi::myescapeHTML($catalog->{'dumplocation'}));
    template_set($assoc, '_NAME_', $name);
    template_set($assoc, '_HIDDEN_', $self->hidden('context' => 'cdump_confirm'));

    return $self->stemplate_build($template);
}

sub cdump_confirm {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($path) = $cgi->param('path');
    $self->serror("you must specify the full path name of a writable directory") if(! -d $path || ! -w $path);
    $path =~ s:/$::o;
    my($location) = $cgi->param('location');
    $self->serror("you must specify a location") if(!$location);
    my($name) = $cgi->param('name');
    $self->update("catalog", "name = '$name'",
		  'dump' => $path,
		  'dumplocation' => $location);
    
    system("rm -fr $path/*");

    my($script) = $ENV{'SCRIPT_NAME'};
    $ENV{'SCRIPT_NAME'} = $location;
    my($rows) = $self->exec_select("select pathname from catalog_path_$name");
    my($row);
    foreach $row (@$rows) {
	my($html) = $self->pathcontext(Catalog::tools::cgi->new({
	    'context' => 'pathcontext',
	    'pathname' => $row->{'pathname'},
	}));
	my($dir) = "$path$row->{'pathname'}";
	mkpath($dir);
	my($file) = "${dir}index.html";
	open(FILE, ">$file") or error("cannot open $file for writing : $!");
	print FILE $html;
	close(FILE);
	$self->gauge();
    }
    if(defined($script)) {
	$ENV{'SCRIPT_NAME'} = $script;
    } else {
	delete($ENV{'SCRIPT_NAME'});
    }
    
    return $self->ccontrol_panel(Catalog::tools::cgi->new({
	'context' => 'ccontrol_panel',
	'comment' => 'The catalog has been dumped'
    }));
}

sub cedit_1 {
    my($self, $cgi, $info) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($id) = $cgi->param('id');
    my($name) = $cgi->param('name');
    my($catalog) = $ccatalog->{$name};
    my($navigation) = $catalog->{'navigation'};
    $self->serror("%s catalog cannot be edited", $navigation) if($navigation ne 'theme');
    $self->pathcheck($name);
    my($root) = $catalog->{'root'};
    if(!defined($id)) {
	$id = $root;
    }
    my($category) = $self->exec_select_one("select * from catalog_category_$name where rowid = $id");

    #
    # Load template
    #
    my($base) = $info->{'mode'};
    if(defined($category->{'info'}) && $category->{'info'} =~ /\broot\b/ && $base eq 'cbrowse') {
	$base .= "_root";
    }
    my($template) = $self->template($base);
    my($assoc) = $template->{'assoc'};

    #
    # Set top level tags
    #
    #
    # Comment
    #
    template_set($assoc, '_COMMENT_', $cgi->param('comment'));
    #
    # Category path
    #
    if(exists($assoc->{'_PATH_'})) {
	$assoc->{'_PATH_'} = $self->cpath();
    }
    #
    # Hidden parameters
    #
    template_set($assoc, '_HIDDEN_', $self->hidden('path' => undef,
						   'context' => undef));
    #
    # Category name
    #
    template_set($assoc, '_CATEGORY_', $category->{'name'});
    #
    # Catalog name
    #
    template_set($assoc, '_NAME_', $name);
    #
    # Context
    #
    template_set($assoc, '_CONTEXT_', $cgi->param('pathname') ? 'pathcontext' : $cgi->param('context'));
    if($info->{'mode'} eq 'cedit') {
	template_set($assoc, '_CONTROLPANEL_', $self->ccall('context' => 'ccontrol_panel',
							    'id' => undef,
							    'name' => undef,
							    'path' => undef));
	my($context);
	foreach $context ('centryinsert', 'centryselect', 'categoryinsert', 'categorysymlink') {
	    my($call) = $self->ccall('context' => $context, 'id' => $id);
	    template_set($assoc, "_" . uc($context) . "_", $call);
	}
	#
	# Symbolic link selection 
	#
	if(exists($template->{'children'}->{'symlink'})) {
	    my($template) = $template->{'children'}->{'symlink'};
	    if(defined($cgi->fct_name()) && $cgi->fct_name() eq 'select') {
		my($assoc) = $template->{'assoc'};
		my($call) = $self->ccall('context' => 'categorysymlink',
					 'rowid' => $id);
		template_set($assoc, "_HTMLPATH_", $self->{'htmlpath'});
		template_set($assoc, "_CATEGORYSYMLINK_", $call);
	    } else {
		$template->{'skip'} = 1;
	    }
	}
    }

    #
    # Show entries
    #
    if(exists($template->{'children'}->{'entry'}) ||
       exists($template->{'children'}->{'row'})) {
	my($table) = $self->cinfo()->{$name}->{'tablename'};
	my($rows) = $self->exec_select("select $table.rowid from $table, catalog_entry2category_$name where $table.rowid = catalog_entry2category_$name.row and catalog_entry2category_$name.category = $id");
	if(@$rows) {
	    $self->cedit_searcher($template, $table, $info, join(',', map { $_->{'rowid'} } @$rows));
	} else {
	    $template->{'children'}->{'entry'}->{'skip'} = 1;
	    $template->{'children'}->{'row'}->{'skip'} = 1;
	    $template->{'children'}->{'pager'}->{'skip'} = 1;
	}
    }

    #
    # Show sub categories
    #
    $self->category_searcher($template->{'children'}->{'categories'}, $id, $info, $category);

    return $self->stemplate_build($template);
}

sub category_searcher {
    my($self, $template, $id, $info, $current_category) = @_;
    my($cgi) = $self->{'cgi'};

    #
    # Define search domain
    #
    my($name) = $cgi->param('name');
    my($catalog) = $self->cinfo()->{$name};
    my($category) = "catalog_category_$name";
    my($category2category) = "catalog_category2category_$name";

    template_set($template->{'assoc'}, '_CATEGORY_', $current_category->{'name'});

    my($where) = '';
    if(defined($catalog->{'info'}) &&
       $catalog->{'info'} =~ /hideempty/ && $info->{'mode'} ne 'cedit') {
	$where = " and a.count > 0 ";
    }
    my($sql) = "select a.rowid,a.name,a.count,b.info,c.pathname from $category as a, $category2category as b, catalog_path_$name as c where a.rowid = b.down and b.down = c.id and b.up = $id $where order by a.name";
#    warn("sql: $sql");
    my($layout) = sub {
	my($template, $name, $result, $context) = @_;

	my($assoc) = $template->{'assoc'};
	my($row) = $result->{$category};
	my($issymlink) = defined($row->{'info'}) && $row->{'info'} =~ /symlink/;
	
	#
	# Build forged tags
	#
	if(exists($assoc->{'_URL_'})) {
	    my($url);
	    if($cgi->param('pathname')) {
		my($pathname) = $row->{'pathname'};
		$url = $cgi->script_name() . $pathname;
	    } else {
		my($path) = $cgi->param('path');
		$url = $self->ccall('context' => $info->{'mode'},
				    'id' => $row->{'rowid'},
				    'path' => join(',', ($path || ()), $row->{'rowid'}));
	    }
	    $assoc->{'_URL_'} = $url;
	}
	#
	# Fix field values
	#
	if($cgi->param('pathname') && $issymlink) {
	    $row->{'count'} = '@';
	}

	$self->searcher_layout_result($template, $name, $result, $context);
    };

    my(%context) = (
		    'context' => 'catalog categories',
		    'template' => $template,
		    'layout' => $layout,
		    'table' => $category,
		    'sql' => $sql,
		    );

    return $self->searcher(\%context);
}

sub cedit_searcher {
    my($self, $template, $table, $info, $primary_values) = @_;

    my($info_table) = $self->info_table($table);
    my($primary_key) = $info_table->{'_primary_'};

    my($where) = "$table.$primary_key in ($primary_values)";

    return $self->catalog_searcher($template, $table, $info, $where, 'id');
}

sub catalog_searcher {
    my($self, $template, $table, $info, $where, $param) = @_;
    my($cgi) = $self->{'cgi'};

    my($info_table) = $self->info_table($table);
    my($primary_key) = $info_table->{'_primary_'};

    #
    # Define search domain
    #
    my($name) = $cgi->param('name');
    my($catalog) = $self->cinfo()->{$name};
    $where = '' if(!defined($where));
    if(defined($catalog->{'cwhere'}) && $catalog->{'cwhere'} !~ /^\s*$/) {
	$where .= " and ($catalog->{'cwhere'})";
    }

    my(%context) = (
		    'context' => 'catalog entries',
		    'params' => [ $param ],
		    'url' => $cgi->url('-absolute' => 1),
		    'page' => scalar($cgi->param('page')),
		    'page_length' => scalar($cgi->param('page_length')),
		    'template' => $template,
		    'expand' => 'yes',
		    'table' => $table,
		    'where' => $where,
		    'order' => $catalog->{'corder'},
		    );

    return $self->searcher(\%context);
}

sub searcher_links {
    my($self, $table, $row, $context) = @_;

    my($imagespath) = "$self->{'htmlpath'}/images";
    my($cgi) = $self->{'cgi'};
    my($name) = $cgi->param('name');
    my($url) = $cgi->url(-absolute => 1);
    if($context->{'context'} eq 'catalog categories') {
	my($id) = $cgi->param('id');
	my($issymlink);
	my(@symlink);
	if($row->{'info'} =~ /\bsymlink\b/) {
	    $issymlink = 1;
	    @symlink = (
			'symlink' => 'yes',
			);
	}
	my($html) = '';
	$html .= "<a href=\"" . $self->ccall('context' => 'categoryremove',
					     'id' => $id,
					     'path' => undef,
					     @symlink,
					     'child' => $row->{'rowid'}) . "\"><img src=$imagespath/cut.gif alt='Remove this category' border=0></a> ";
	if(!$issymlink) {
	    $html .= "<a href=\"" . $self->ccall('context' => 'categoryedit',
						 'child' => $row->{'rowid'},
						 'id' => $id) . "\"><img src=$imagespath/edit.gif alt='Edit category properties' border=0></a> ";
	}
	return $html;
    } elsif($context->{'context'} eq 'catalog entries') {
	my($info) = $self->info_table($table);
	my($primary_key) = $info->{'_primary_'};
	my($id) = $cgi->param('id');
	my($html);
	my(%spec) = (
		     'centryremove' => ['Unlink from this category', 'unlink'],
		     'centryremove_all' => ['Unlink from all categories and remove record', 'cut'],
		     );
	my($tag, $label);
	foreach $tag (sort(keys(%spec))) {
	    my($label, $image) = @{$spec{$tag}};
	    $html .= "<a href=\"" . $self->ccall('row' => $row->{$primary_key},
						 'context' => $tag,
						 'id' => $id) . "\"><img src=$imagespath/$image.gif alt='$label' border=0></a> ";
	}
	$html .= "<a href=\"" . $self->ccall('row' => $row->{$primary_key},
					     'context' => 'centryedit',
					     'id' => $id) . "\"><img src=$imagespath/edit.gif alt='Edit the record' border=0></a> ";
	return $html;
    } else {
	return $self->Catalog::tools::sqledit::searcher_links($table, $row, $context);
    }
}

sub cpath {
    my($self) = @_;
    my($cgi) = $self->{'cgi'};

    my($path) = $cgi->param('path');
    my($id) = $cgi->param('id');
    my($name) = $cgi->param('name');
    my($pathname) = $cgi->param('pathname');

    my($url);
    if(defined($pathname)) {
	$url = $self->{'cgi'}->url(-absolute => 1);
    } else {
	$url = $self->ccall(path => undef, id => undef);
    }

    return $self->cpath2html($name, $id, $path, $url, undef, $pathname);
}

#
# Return the list of html path where a given record is stored
#
sub crowid2paths {
    my($self, $name, $rowid, $url) = @_;

    my($category2entry) = "catalog_entry2category_$name";
    my($rows) = $self->exec_select("select category from $category2entry where row = $rowid");
    my(@paths);
    my($row);
    foreach $row (@$rows) {
	push(@paths, $self->cpath2html($name, $row->{'category'}, undef, $url, 'including'));
    }
    return (@paths ? \@paths : undef);
}

sub crowid2categories {
    my($self, $name, $rowid, $url) = @_;

    my($category2entry) = "catalog_entry2category_$name";
    my($category) = "catalog_category_$name";
    my($rows) = $self->exec_select("select a.rowid,a.name from $category as a,$category2entry as b where b.row = $rowid and b.category = a.rowid");
    my(@categories);
    my($row);
    foreach $row (@$rows) {
	push(@categories, "<a href=$url&id=$row->{'rowid'}>$row->{'name'}</a>");
    }
    return (@categories ? \@categories : undef);
}

sub cpath2html {
    my($self, $name, $id, $path, $url, $including, $pathname) = @_;

    my($catalog) = $self->cinfo()->{$name};
    my($category) = "catalog_category_$name";
    my($root) = $catalog->{'root'};

    if(!defined($path) || $path eq '') {
	$path = $self->cid2path($name, $id);
    }
    return undef if(!defined($path) || $path eq '');
    
    $path .= ",$id" if($including);
    my($html) = '';
    my($root_label) = $self->{'path_root_label'} || 'root';
    my($sep) = $self->{'path_separator'} || ':';

    if(defined($pathname)) {
	$html .= "<a href=$url/>$root_label</a>$sep";

	my($new_path) = '/';
	my(@names) = split('/', substr($pathname, 1, -1));
	my($count) = scalar(@names);
	my($i) = 1;
	foreach $name (@names) {
	    my($printed_name) = $name;
	    $printed_name =~ s/_/ /go;
	    $new_path .= "$name/";
	    if($i >= $count) {
		$html .= "$printed_name";
	    } else {
		$html .= "<a href=$url$new_path>$printed_name</a>$sep";
	    }
	    $i++;
	}
    } else {
	$html .= "<a href=$url&id=$root>$root_label</a>$sep";

	my($rows) = $self->exec_select("select rowid,name from $category where rowid in ( $path )");
	$rows = { map { $_->{'rowid'} => $_ } @$rows };

	my($new_path) = '';
	my($rowid);
	my(@path) = split(',', $path);
	my($last) = $path[$#path];
	foreach $rowid (@path) {
	    my($row) = $rows->{$rowid};
	    $new_path .= "$rowid";
	    if($rowid eq $last) {
		$html .= "$row->{'name'}";
	    } else {
		$html .= "<a href=$url&id=$row->{'rowid'}&path=$new_path>$row->{'name'}</a>$sep";
	    }
	    $new_path .= ",";
	}
    }
    return $html;
}

sub cid2path {
    my($self, $name, $id) = @_;

    my($catalog) = $self->cinfo()->{$name};
    my($root) = $catalog->{'root'};
    my($category2category) = "catalog_category2category_$name";

    my(@path);
    while($id ne $root) {
	push(@path, $id);
	$id = $self->exec_select_one("select up from $category2category where down = $id")->{'up'};
    }

    return join(',', reverse(@path));
}

sub walk {
    my($self, $func, @ids) = @_;
    
    my($cgi) = $self->{'cgi'};

    my($name) = $cgi->param('name');
    if(!@ids) {
	my($catalog) = $self->cinfo()->{$name};
	push(@ids, $catalog->{'root'});
    }

    my($id);
    foreach $id (@ids) {
	$self->walk_1($func, $name, $id);
    }
}

sub walk_1 {
    my($self, $func, $name, $id) = @_;

    my($rows) = $self->exec_select("select row from catalog_entry2category_$name where catalog_entry2category_$name.category = $id");
    my($row);
    foreach $row (@$rows) {
	return if(!&$func($row->{'row'}));
    }

    ($rows) = $self->exec_select("select a.rowid from catalog_category_$name as a, catalog_category2category_$name as b where a.rowid = b.down and b.up = $id");

    foreach $row (@$rows) {
	$self->walk_1($func, $name, $row->{'rowid'});
    }
}

sub walk_categories {
    my($self, $name, $func) = @_;
    
    my($cgi) = $self->{'cgi'};

    my($catalog) = $self->cinfo()->{$name};
    my($id) = $catalog->{'root'};

    $self->walk_categories_1($func, $name, $id);
}

sub walk_categories_1 {
    my($self, $func, $name, $id, $path, $pathid) = @_;

    my($rows) = $self->exec_select("select a.rowid,a.name from catalog_category_$name as a, catalog_category2category_$name as b where a.rowid = b.down and b.up = $id and (b.info is null or not find_in_set('symlink', b.info))");

    my($row);
    foreach $row (@$rows) {
	my($path_tmp) = $path ? "$path/$row->{'name'}" : $row->{'name'};
	my($pathid_tmp) = $pathid ? "$pathid,$row->{'rowid'}" : $row->{'rowid'};
	
	return if(!&$func($row->{'rowid'}, $row->{'name'}, $path_tmp, $pathid_tmp));
	$self->walk_categories_1($func, $name, $row->{'rowid'}, $path_tmp, $pathid_tmp);
    }
}

#
# Fill template with specified categories
#
sub category_display {
    my($self, $template, $ids) = @_;
    my($cgi) = $self->{'cgi'};

    my($name) = $cgi->param('name');
    my($category) = "catalog_category_$name";

    my($sql);
    if(defined($ids)) {
	my($limit) = join(',', @$ids);
	$sql = "select a.rowid,a.name,a.count from $category as a where a.rowid in ($limit)";
    } else {
	my($catalog) = $self->cinfo()->{$name};
	my($id) = $catalog->{'root'};
	my($category2category) = "catalog_category2category_$name";
	$sql = "select a.rowid,a.name,a.count,b.info from $category as a, $category2category as b where a.rowid = b.down and b.up = $id";
    }

    my(%context) = (
		    'context' => 'catalog categories display',
		    'template' => $template,
		    'table' => $category,
		    'sql' => $sql,
		    );

    return $self->searcher(\%context);
}

sub category_rows {
    my($self, $template, $rows, $info) = @_;

    if(@$rows <= 0) {
	$template->{'skip'} = 1;
	return;
    }
    
    my($html) = '';
    my($params) = $template->{'params'};
    if(!exists($params->{'style'}) || $params->{'style'} eq 'list') {
	my($template_entry) = $template->{'children'}->{'entry'};

	my($row);
	foreach $row (@$rows) {
	    $html .= $self->category_row($template_entry, $row, $info);
	}
	$template_entry->{'html'} = $html;
    } elsif($params->{'style'} eq 'table') {
	my($template_row) = $template->{'children'}->{'row'};
	my($template_entry) = $template_row->{'children'}->{'entry'};
	my($count_max) = $params->{'columns'} || 5;
	my($count) = 0;
	my($columns) = '';
	my($row);
	foreach $row (@$rows) {
	    if($count >= $count_max) {
		$template_entry->{'html'} = $columns;
		$html .= $self->stemplate_build($template_row);
		$columns = '';
		$count = 0;
	    }
	    $count++;
	    $columns .= $self->category_row($template_entry, $row, $info);
	}
	if($count > 0) {
	    $template_entry->{'html'} = $columns;
	    $html .= $self->stemplate_build($template_row);
	}
	$template_row->{'html'} = $html;
    } else {
	croak("unknown style $params->{'style'}");
    }
}

sub category_row {
    my($self, $template, $row, $info) = @_;
    my($cgi) = $self->{'cgi'};

    my($assoc) = $template->{'assoc'};
    template_set($assoc, '_NAME_', $row->{'name'});
    template_set($assoc, '_ROWID_', $row->{'rowid'});
    if(exists($assoc->{'_URL_'})) {
	my($path) = $cgi->param('path');
	my($url) = $self->ccall('context' => $info->{'mode'},
				'id' => $row->{'rowid'},
				'path' => join(',', ($path || ()), $row->{'rowid'}));
	$assoc->{'_URL_'} = $url;
    }
    if(defined($row->{'info'}) && $row->{'info'} =~ /symlink/) {
	template_set($assoc, '_COUNT_', '@');
    } else {
	template_set($assoc, '_COUNT_', $row->{'count'});
    }

    return $self->stemplate_build($template);
}

sub ccount {
    my($self, $rowid, $increment) = @_;
    my($cgi) = $self->{'cgi'};
    my($name) = $cgi->param('name');

#    warn("update catalog_category_$name set count = count $increment where rowid = $rowid");
    $self->update("catalog_category_$name", "rowid = $rowid",
		  '+= count' => $increment);

    my($rows) = $self->exec_select("select a.rowid from catalog_category_$name as a, catalog_category2category_$name as b where a.rowid = b.up and b.down = $rowid and (b.info is null or not find_in_set('symlink', b.info))");
    my($row);
    foreach $row (@$rows) {
	$self->ccount($row->{'rowid'}, $increment);
    }
}

sub categoryremove {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    my($id) = $cgi->param('child');
    my($symlink) = $cgi->param('symlink');
    my($category) = "catalog_category_$name";
    my($category2category) = "catalog_category2category_$name";
    my($entry2category) = "catalog_entry2category_$name";
    my($row) = $self->exec_select_one("select * from $category where rowid = $id");
    #
    # Sanity checks
    #
    $self->serror("no category found for id = $id") if(!defined($row));
    if(!defined($symlink)) {
	$self->serror("category has sub categories") if($self->exec_select_one("select down from $category2category where up = $id"));
	$self->serror("category is not empty") if($row->{'count'} > 0);
	$self->serror("entries are still linked to this category") if($self->exec_select_one("select row from $entry2category where category = $id"));
    }

    #
    # Effective deletion
    #
    if(!defined($symlink)) {
	$self->mdelete($category, "rowid = $id");
	$self->mdelete($category2category, "down = $id");
	$self->mdelete("catalog_path_$name", "id = $id");
    } else {
	my($parent) = $cgi->param('id');
	$self->mdelete($category2category, "down = $id and up = $parent");
    }

    $cgi->param('context', 'cedit');
    return $self->cedit($cgi);
}

sub categoryinsert {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    #
    # Show a form to create a new category
    #
    if(!defined($cgi->param('rowid'))) {
	my($name) = $cgi->param('name');
	$self->pathcheck($name);
	my($table) = "catalog_category_$name";
	my($params) = $self->params('context' => 'insert_form',
				    'style' => 'catalog_category',
				    'table' => $table,
				    'name' => undef);
	eval {
	    $cgi = $cgi->fct_call($params,
				  'name' => 'insert',
				  'args' => { },
				  'returned' => {
				      'fields' => 'rowid',
				      'context' => 'categoryinsert',
				  });
	};
	if($@) {
	    my($error) = $@;
	    print STDERR $error;
	    $self->serror("recursive cgi call failed, check logs");
	}
	return $self->insert_form($cgi);
    } else {
	my($name) = $cgi->param('name');
	#
	# Link the created category to its parent
	#
	my($up_id) = $cgi->param('id');
	my($down_id) = $cgi->param('rowid');
	$self->categoryinsert_api($name, $up_id, $down_id);
	$cgi->param('context', 'cedit');
	return $self->cedit($cgi);
    }
    
}

sub categoryinsert_api {
    my($self, $name, $up_id, $down_id) = @_;

    $self->insert("catalog_category2category_$name",
		  'info' => 'hidden',
		  'up' => $up_id,
		  'down' => $down_id);
    #
    # Create the path entry
    #
    my($down_category) = $self->exec_select_one("select rowid,name from catalog_category_$name where rowid = $down_id");
    my($up_path) = $self->exec_select_one("select * from catalog_path_$name where id = $up_id");
    my($pathname) = "$up_path->{'pathname'}$down_category->{'name'}/";
    $pathname = $self->path2url($pathname);
    my($path) = $up_path->{'path'} ? "$up_path->{'path'}$down_category->{'rowid'}," : ",$down_category->{'rowid'},";
    $self->insert("catalog_path_$name",
		  'pathname' => $pathname,
		  'md5' => MD5->hexhash($pathname),
		  'path' => $path,
		  'id' => $down_category->{'rowid'}
		  );
}

sub path2url {
    my($self, $string) = @_;

    $string =~ s/[ \'\"]/_/og;
    return $string;
}

sub categoryedit {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    #
    # Editing form
    #
    my($child) = $cgi->param('child');
    my($table) = "catalog_category_" . $cgi->param('name');
    my($params) = $self->params('context' => 'edit',
				'style' => 'catalog_category',
				'table' => $table,
				'primary' => $child,
				'name' => undef);
    eval {
	$cgi = $cgi->fct_call($params,
			      'name' => 'edit',
			      'args' => { },
			      'returned' => {
				  'context' => 'categoryedit_done',
			      });
    };
    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->serror("recursive cgi call failed, check logs");
    }
    return $self->edit($cgi);
}

sub categoryedit_done {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    $self->pathcheck($name);
    my($child) = $cgi->param('child');
    my($child_length) = length($child);
    #
    # Replace the name of the category in path table
    #
    my($category) = $self->exec_select_one("select name from catalog_category_$name where rowid = $child");
    my($category_name) = $self->path2url($category->{'name'});
    my($rows) = $self->exec_select("select pathname,path,id from catalog_path_$name where path like '%,$child,%'");
    my($row);
    foreach $row (@$rows) {
	#
	# Find position of component to replace by searching the $child in path. Position
	# is stored in $count.
	#
	my($i) = 0;
	my($count) = 1;
	do { $count++; $i++; } while(($i = index($row->{'path'}, ',', $i)) &&
				     substr($row->{'path'}, $i + 1, $child_length) ne $child);
	$i++;
#	warn("child = $child, found = " . substr($row->{'path'}, $i, $child_length) . "\n");
	#
	# Find exact position and length of component to replace by counting the / in pathname
	# (skip $count of them).
	#
	$i = 0;
	while($count) { $i = index($row->{'pathname'}, '/', $i); $i++; $count--; }
	my($name_length) = index($row->{'pathname'}, '/', $i) - $i;
#	warn("child = $child, found = " . substr($row->{'pathname'}, $i, $name_length) . "\n");
	#
	# Substitute old category name with new one
	#
	substr($row->{'pathname'}, $i, $name_length, $category_name);
#	warn("changed to $row->{'pathname'}");
	#
	# Change in table and update the md5 key
	#
	$self->update("catalog_path_$name", "id = $row->{'id'}",
		      'pathname' => $row->{'pathname'},
		      'md5' => MD5->hexhash($row->{'pathname'}));
    }

    $cgi->param('context' => 'cedit');
    $self->cedit($cgi);
}

sub centryedit {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    #
    # Editing form
    #
    my($name) = $cgi->param('name');
    my($table) = $ccatalog->{$name}->{'tablename'};
    my($params) = $self->params('context' => 'edit',
				'primary' => $cgi->param('row'),
				'table' => $table,
				'name' => undef);
    eval {
	$cgi = $cgi->fct_call($params,
			      'name' => 'edit',
			      'args' => { },
			      'returned' => {
				  'context' => 'cedit',
			      });
    };
    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->serror("recursive cgi call failed, check logs");
    }
    return $self->edit($cgi);
}

sub centryselect {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();
    
    my($name) = $cgi->param('name');
    my($table) = $ccatalog->{$name}->{'tablename'};
    
    my($params) = $self->params('context' => 'search_form',
				'table' => $table,
				'name' => undef);

    eval {
	$cgi = $cgi->fct_call($params,
			      'name' => 'select',
			      'args' => { },
			      'returned' => {
				  'fields' => 'rowid',
				  'context' => 'centryinsert',
			      });
    };
    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->serror("recursive cgi call failed, check logs");
    }
    return $self->search_form($cgi);
}

sub centryremove_all {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($table) = $cgi->param('table');

    my($template) = $self->template("centryremove_all");

    template_set($template->{'assoc'}, '_HIDDEN_',
		 $self->hidden('id' => $cgi->param('id'),
			       'row' => $cgi->param('row'),
			       'context' => 'centryremove_all_confirm'));
    
    return $self->stemplate_build($template);
}

sub centryremove_all_confirm {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    #
    # Remove all the links between the entry and the categories
    #
    my($primary_value) = $cgi->param('row');
    my($rows) = $self->exec_select("select category from catalog_entry2category_$name where row = $primary_value");
    if(defined($rows)) {
	my($row);
	foreach $row (@$rows) {
	    my($id) = $row->{'category'};
	    
	    $self->mdelete("catalog_entry2category_$name",
			   "row = $primary_value and category = $id");
	    $self->ccount($id, '-1');
	}
    }
    #
    # Remove the entry itself
    #
    my($ccatalog) = $self->cinfo();
    my($table) = $ccatalog->{$name}->{'tablename'};
    my($primary_key) = $self->info_table($table)->{'_primary_'};
    $self->mdelete($table, "$primary_key = $primary_value");

    $cgi->param('context', 'cedit');
    return $self->cedit($cgi);
}

sub centryremove {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    #
    # Remove the link between the entry and the category
    #
    my($id) = $cgi->param('id');
    my($row) = $cgi->param('row');
    $self->mdelete("catalog_entry2category_$name",
		   "row = $row and category = $id");
    $self->ccount($id, '-1');

    $cgi->param('context', 'cedit');
    return $self->cedit($cgi);
}

sub centryinsert {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    #
    # Show a form to create a new entry
    #
    my($name) = $cgi->param('name');
    my($table) = $ccatalog->{$name}->{'tablename'};
    if(!defined($cgi->param('rowid'))) {
	my($params) = $self->params('context' => 'insert_form',
				    'table' => $table,
				    'name' => undef);
	eval {
	    $cgi = $cgi->fct_call($params,
				  'name' => 'insert',
				  'args' => { },
				  'returned' => {
				      'fields' => 'rowid',
				      'context' => 'centryinsert',
				  });
	};
	if($@) {
	    my($error) = $@;
	    print STDERR $error;
	    $self->serror("recursive cgi call failed, check logs");
	}
	return $self->insert_form($cgi);
    } else {
	my($name) = $cgi->param('name');
	#
	# Link the created entry to its category
	#
	my($id) = $cgi->param('id');
	$self->insert("catalog_entry2category_$name",
		      'info' => 'hidden',
		      'row' => $cgi->param('rowid'),
		      'category' => $id);
	$self->ccount($id, '+1');

	$cgi->param('context', 'cedit');
	return $self->cedit($cgi);
    }
}

sub cbuild {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($error);
    my($navigation) = $cgi->param('navigation');
    my($table) = $cgi->param('table');
    #
    # Show a form to create a new catalog
    #
    if(!defined($cgi->param('rowid'))) {
	$error = $self->cbuild_check('', $table, $navigation, 'step1');
	if(!defined($error)) {
	    my($style) = "catalog_$navigation";
	    my($params) = $self->params('context' => 'insert_form',
					'table' => 'catalog',
					'navigation' => $navigation,
					'style' => $style,
					'tablename' => $table,
					'name' => undef);
	    eval {
		$cgi = $cgi->fct_call($params,
				      'name' => 'insert',
				      'args' => { },
				      'returned' => {
					  'fields' => 'rowid,name,tablename,fieldname,navigation',
					  'context' => 'cbuild',
				      });
	    };
	    if($@) {
		my($error) = $@;
		print STDERR $error;
		$self->serror("recursive cgi call failed, check logs");
	    }
	    return $self->insert_form($cgi);
	}
    } else {
	my($rowid) = $cgi->param('rowid');
	my($name) = $cgi->param('name');
	my($field)= $cgi->param('fieldname');
	$error = $self->cbuild_check($name, $table, $navigation, 'step2', $field);

	if(!defined($error)) {
	    $self->cbuild_real($rowid, $name, $table, $navigation, $field);
	} else {
	    $self->exec("delete from catalog where rowid = $rowid");
	}
    }
    return $self->ccontrol_panel(Catalog::tools::cgi->new({
	'context' => 'ccontrol_panel',
	'comment' => $error,
	'table' => $table,
	'navigation' => $navigation,
    }));
}

sub cbuild_api {
    my($self, %record) = @_;

    my($error) = $self->cbuild_check($record{'name'},
				     $record{'tablename'},
				     $record{'navigation'},
				     'step2',
				     $record{'fieldname'});
    
    error($error) if(defined($error));
    
    my($rowid) = $self->insert("catalog",
			       %record);

    $self->cbuild_real($rowid,
		       $record{'name'},
		       $record{'tablename'},
		       $record{'navigation'},
		       $record{'fieldname'});

    $self->cinfo_clear();
}

sub cbuild_real {
    my($self, $rowid, $name, $table, $navigation, $field) = @_;
    
    eval {
	if(!$navigation || $navigation =~ /theme/) {
	    $self->cbuild_theme($name, $rowid);
	} elsif($navigation eq 'date') {
	    $self->cbuild_date($name, $rowid, $field);
	} else {
	    $self->cbuild_alpha($name, $rowid, $field);
	}
    };
    #
    # Construction of the catalog failed, rewind
    #
    if($@) {
	my($error) = $@;
	$self->exec("delete from catalog where rowid = $rowid");
	error($error);
    }

    $self->cinfo_clear();
}

sub cbuild_alpha {
    my($self, $name, $rowid, $field) = @_;

    #
    # Create catalog tables
    #
    my($table);
    foreach $table (@tablelist_alpha) {
	my($schema) = $schema{$table};
	$schema =~ s/NAME/$name/g;
	$self->exec($schema);
    }

    my($letter);
    foreach $letter ('0'..'9', 'a'..'z') {
	$self->insert("catalog_alpha_$name",
		      'letter' => $letter);
    }
}

sub cbuild_date {
    my($self, $name, $rowid, $field) = @_;

    #
    # Create catalog tables
    #
    my($table);
    foreach $table (@tablelist_date) {
	my($schema) = $schema{$table};
	$schema =~ s/NAME/$name/g;
	$self->exec($schema);
    }
}

sub cbuild_check {
    my($self, $name, $table, $navigation, $step, $field) = @_;

    return undef if($::opt_fake);

    if($step eq 'step2') {
	my($name_quoted) = $self->quote($name);
	return "you must specify the name of the catalog (name)" if(!$name);
    }
    return "you must specify a table name (tablename)" if(!$table);
    return "the table $table does not exist (tablename)" if(!grep($table eq $_, @{$self->tables()}));
    
    if($navigation eq 'theme') {
	my($info) = $self->info_table($table);
	if(!exists($info->{'_primary_'}) ||
	   $info->{'_primary_'} ne 'rowid' ||
	   $info->{$info->{'_primary_'}}->{'type'} ne 'int') {
	    return "the table $table does not have a unique primary numerical key named rowid";
	}

    } elsif($step eq 'step2' &&
	    ($navigation eq 'date' ||
	     $navigation eq 'alpha')) {
	my($info) = $self->info_table($table);
	return "a field name must be specified for date catalogs (fieldname)" if(!$field);
	return "$field is not a field of $table (fieldname)" if(!exists($info->{$field}));
	if($navigation eq 'date') {
	    return "$field of table $table is not a field of type date or time" if($info->{$field}->{'type'} ne 'date' && $info->{$field}->{'type'} ne 'time');
	} elsif($navigation eq 'alpha') {
	    return "$field of table $table is not a field of type char" if($info->{$field}->{'type'} ne 'char');
	}
    }
    return undef;
}

sub cbuild_theme {
    my($self, $name, $rowid) = @_;

    #
    # Create catalog tables
    #
    my($table);
    foreach $table (@tablelist_theme) {
	my($schema) = $schema{$table};
	$schema =~ s/NAME/$name/g;
	$self->exec($schema);
    }
    #
    # Create root of catalog
    #
    my($root_rowid) = $self->insert("catalog_category_$name",
				    'info' => 'root',
				    'name' => '');

    $self->insert("catalog_path_$name",
		  'pathname' => '/',
		  'md5' => MD5->hexhash('/'),
		  'path' => ' ',
		  'id' => $root_rowid);
    #
    # Register root in catalog table
    #
    $self->update("catalog", "rowid = '$rowid'",
		  'root' => $root_rowid);
    
}

sub ccatalog_edit {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    #
    # Edit the informations about the catalog
    #
    my($name) = $cgi->param('name');
    my($rowid) = $ccatalog->{$name}->{'rowid'};
    my($navigation) = $ccatalog->{$name}->{'navigation'};
    my($params) = $self->params('context' => 'edit',
				'table' => 'catalog',
				'style' => "catalog_$navigation",
				'primary' => $rowid);
    eval {
	$cgi = $cgi->fct_call($params,
			      'name' => 'edit',
			      'args' => { },
			      'returned' => {
				  'context' => 'ccatalog_edit_done',
			      });
    };
    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->serror("recursive cgi call failed, check logs");
    }
    return $self->edit($cgi);
}

sub ccatalog_edit_done {
    my($self, $cgi) = @_;

    $self->cinfo_clear();

    return $self->ccontrol_panel(Catalog::tools::cgi->new({
	'context' => 'ccontrol_panel',
    }));
}

#
# When generating sqledit calls, strip catalog name and path
#
sub call {
    my($self, $table, $info, $row, %pairs) = @_;

    my($tag);
    foreach $tag ('name', 'path') {
	$pairs{$tag} = undef if(!defined($pairs{$tag}));
    }

    return $self->Catalog::tools::sqledit::call($table, $info, $row, %pairs);
}

sub ccall {
    my($self, %pairs) = @_;

    my($params) = $self->params(%pairs);
    my($script) = $self->{'cgi'}->url(-absolute => 1);
    return "$script?$params";
}

sub cerror {
    my($self, $cgi, $message) = @_;

    my($template) = $self->template("error");
    $template->{'assoc'}->{'_MESSAGE_'} = $message;
    return $self->stemplate_build($template);
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
