BASE = catalog_example

include ../conf/install.conf
include ../conf/mysql.conf

all:

install:
	rm -fr $(htmldir)/index.html $(cgidir)/browse $(cgidir)/admin
	perl -p -e 's|_CGIPATH_|$(cgipath)|g' < index.html > $(htmldir)/index.html
	cp -rp admin browse $(cgidir)
	cd $(cgidir)/browse ; \
	cp $(cgidir)/Catalog . ; \
	perl -p -e 's|^base.*|base = $(BASE)|' < $(config_dir)/mysql.conf > mysql.conf ; \
	ln -s ../cgi.conf . ; \
	ln -s ../db.conf . ; \
	ln -s ../install.conf . ; \
	perl -pi -e 's|_HTMLPATH_|$(htmlpath)|' sqledit.conf
	cd $(cgidir)/admin ; \
	cp $(cgidir)/Catalog . ; \
	perl -p -e 's|^base.*|base = $(BASE)|' < $(config_dir)/mysql.conf > mysql.conf ; \
	ln -s ../cgi.conf . ; \
	ln -s ../db.conf . ; \
	ln -s ../install.conf . ; \
	perl -pi -e 's|_HTMLPATH_|$(htmlpath)|' sqledit.conf
	$(MAKE) load

clean:

realclean:

TABLES_ALL = catalog catalog_category2category_urlcatalog catalog_category_urlcatalog catalog_entry2category_urlcatalog catalog_path_urlcatalog catalog_alpha_urlalpha urldemo
TABLES_STRUCTURE = catalog_date_urldate

load:
	@if mysql $(cmd_opt) -e "create database $(BASE)" 2>/dev/null ; \
	then \
		mysql $(cmd_opt) $(BASE) < example.sql ; \
		mysql $(cmd_opt) -e "update catalog set updated = 0" $(BASE) < example.sql ; \
		echo "The example database has been loaded." ; \
	else \
		echo "Example not loaded because the base $(BASE) exists." ; \
	fi

dump:
	mysqldump $(cmd_opt) $(BASE) $(TABLES_ALL) > example.sql
	mysqldump $(cmd_opt) --no-data $(BASE) $(TABLES_STRUCTURE) >> example.sql

drop:
	mysql $(cmd_opt) -e "drop database $(BASE)"

test:
