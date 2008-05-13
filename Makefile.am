## Process this file with automake to produce Makefile.in
lisp_LISP = ephotodb.el

docdir = $(datadir)/doc/$(PACKAGE)-$(VERSION)
doc_DATA = ephotodb-manual.pdf ephotodb-manual/*

info_TEXINFOS = ephotodb.texi

EXTRA_DIST = $(lisp_LISP) $(doc_DATA) $(manual_DATA) ephotodb-manual.xml ephotodb.texi autogen.sh manual-fo.xsl manual.css photo.mysql.sql photo.sqlite.sql

MAINTAINERCLEANFILES = $(doc_DATA) ephotodb-manual.fo ephotodb.texi

fosheet="manual-fo.xsl"

htmlsheet="http://docbook.sourceforge.net/release/xsl/current/html/chunk.xsl"

all: ephotodb-manual.pdf ephotodb-manual/* ephotodb.texi

ephotodb-manual.pdf: ephotodb-manual.xml
	xsltproc --param fop1.extensions 1 --param fop.extensions 0 --stringparam funcsynopsis.style ansi $(fosheet) ephotodb-manual.xml > ephotodb-manual.fo
	fop -fo ephotodb-manual.fo -pdf ephotodb-manual.pdf

ephotodb-manual/*: ephotodb-manual.xml
	rm -rf ephotodb-manual/*
	mkdir -p ephotodb-manual
	xsltproc --stringparam funcsynopsis.style ansi --stringparam html.stylesheet manual.css -o ephotodb-manual/ $(htmlsheet) ephotodb-manual.xml
	cp manual.css ephotodb-manual

ephotodb.texi: ephotodb-manual.xml
	@mydb2texi@ --to-stdout ephotodb-manual.xml > $@


