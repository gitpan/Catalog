BASE = catalog_example

include ../config.cache

all:

install:
	rm -fr $(HTMLDIR)/index.html $(CGIDIR)/browse $(CGIDIR)/admin
	perl -p -e 's|_CGIPATH_|$(CGIPATH)|g' < index.html > $(HTMLDIR)/index.html
	cp -rp admin browse $(CGIDIR)
	cd $(CGIDIR)/browse ; \
	cp $(CGIDIR)/Catalog . ; \
	perl -p -e 's|^base.*|base = $(BASE)|' < $(CONFIG_DIR)/mysql.conf > mysql.conf ; \
	ln -s ../cgi.conf . ; \
	perl -pi -e 's|_HTMLPATH_|$(HTMLPATH)|' sqledit.conf
	cd $(CGIDIR)/admin ; \
	cp $(CGIDIR)/Catalog . ; \
	perl -p -e 's|^base.*|base = $(BASE)|' < $(CONFIG_DIR)/mysql.conf > mysql.conf ; \
	ln -s ../cgi.conf . ; \
	perl -pi -e 's|_HTMLPATH_|$(HTMLPATH)|' sqledit.conf
	$(MAKE) load

clean:

TABLES_ALL = catalog catalog_category2category_urlcatalog catalog_category_urlcatalog catalog_entry2category_urlcatalog catalog_path_urlcatalog catalog_alpha_urlalpha urldemo
TABLES_STRUCTURE = catalog_date_urldate

load:
	@if mysql $(MYSQL_OPT) -e "create database $(BASE)" 2>/dev/null ; \
	then \
		mysql $(MYSQL_OPT) $(BASE) < example.sql ; \
		mysql $(MYSQL_OPT) -e "update catalog set updated = 0" $(BASE) < example.sql ; \
		echo "The example database has been loaded." ; \
	else \
		echo "Example not loaded because the base $(BASE) exists." ; \
	fi

dump:
	mysqldump $(MYSQL_OPT) $(BASE) $(TABLES_ALL) > example.sql
	mysqldump $(MYSQL_OPT) --no-data $(BASE) $(TABLES_STRUCTURE) >> example.sql

drop:
	mysql $(MYSQL_OPT) -e "drop database $(BASE)"
