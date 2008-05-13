#!/bin/sh

# HACK HACK HACK! The autotools want the .texi file but we generate
# it from the DocBook sources at build time. We create a mock
# file and remove it again after the autotools have done their magic
echo "@setfilename ephotodb.info" >ephotodb.texi
aclocal
automake --add-missing
autoconf
rm ephotodb.texi
