all: all_info catalog_toc.html catalog.ps

all_info: catalog.info

all_html: catalog_toc.html

IMAGES_GIF = $(shell echo images/*.gif)
IMAGES_EPS = $(patsubst %.gif,%.eps,$(IMAGES_GIF))
IMAGES_TXT = $(patsubst %.gif,%.txt,$(IMAGES_GIF))

catalog.ps: catalog.texinfo $(IMAGES_EPS) $(IMAGES_TXT)
	texi2dvi catalog.texinfo
	dvips -o catalog.ps catalog.dvi

catalog_toc.html: catalog.texinfo
	rm -fr tmp ; mkdir tmp ; cd tmp ; ln -s ../images .
	perl -p -e 's/^\s*\@/\@/' < catalog.texinfo > tmp/catalog.texinfo
	cd tmp ; texi2html -acc -split_node catalog.texinfo ; rm catalog.texinfo images ; mv * ..
	rm -fr tmp

#
# makeinfo 3.12 dumps core on @image
#
catalog.info: catalog.texinfo # $(IMAGES_TXT)
	grep -v '@image' < catalog.texinfo > c.texinfo 
	makeinfo c.texinfo
	rm -f c.texinfo

install: all
	$(MAKE) install_html
	$(MAKE) install_info

install_info: all_info
	cp catalog.info* $(INFODIR)
	if [ -w $(INFODIR)/dir ] ; \
	then \
		if grep 'Catalog:' $(INFODIR)/dir > /dev/null ; \
		then : ; \
		else \
			if [ ! -f $(INFODIR)/dir.gz -o -w $(INFODIR)/dir.gz ] ; \
			then \
				echo '* Catalog: (catalog)	HTML based resource directory builder' >> $(INFODIR)/dir ; \
				if [ -f $(INFODIR)/dir.gz ] ; \
				then \
					gzip < $(INFODIR)/dir > $(INFODIR)/dir.gz ; \
				fi ; \
			fi ; \
		fi ; \
	fi

install_html: all_html
	cp catalog_*.html $(HTMLDIR)
	if [ ! -d $(HTMLDIR)/images ] ; then mkdir -p $(HTMLDIR)/images ; fi
	cp images/*.gif $(HTMLDIR)/images

clean:
	rm -f catalog.aux catalog.cp catalog.dvi catalog.fn 
	rm -f catalog.info*
	rm -f catalog.ky catalog.log catalog.pg catalog.ps
	rm -f catalog.toc catalog.tp catalog.vr catalog.cps catalog.fns
	rm -f catalog_*.html catalog.info-? texput.log
	rm -f $(IMAGES_EPS) $(IMAGES_TXT)
	rm -fr tmp

test:

%.eps:%.gif
	giftopnm < $*.gif | pnmtops -rle -noturn > $*.eps

%.txt:%.gif
	echo "[$* image]" > $*.txt
