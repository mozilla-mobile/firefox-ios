lxml is a Pythonic, mature binding for the libxml2 and libxslt libraries.  It
provides safe and convenient access to these libraries using the ElementTree
API.

It extends the ElementTree API significantly to offer support for XPath,
RelaxNG, XML Schema, XSLT, C14N and much more.

To contact the project, go to the `project home page
<http://lxml.de/>`_ or see our bug tracker at
https://launchpad.net/lxml

In case you want to use the current in-development version of lxml,
you can get it from the github repository at
https://github.com/lxml/lxml .  Note that this requires Cython to
build the sources, see the build instructions on the project home
page.  To the same end, running ``easy_install lxml==dev`` will
install lxml from
https://github.com/lxml/lxml/tarball/master#egg=lxml-dev if you have
an appropriate version of Cython installed.


After an official release of a new stable series, bug fixes may become
available at
https://github.com/lxml/lxml/tree/lxml-3.6 .
Running ``easy_install lxml==3.6bugfix`` will install
the unreleased branch state from
https://github.com/lxml/lxml/tarball/lxml-3.6#egg=lxml-3.6bugfix
as soon as a maintenance branch has been established.  Note that this
requires Cython to be installed at an appropriate version for the build.

3.6.0 (2016-03-17)
==================

* GH#189: Static builds honour FTP proxy configurations when downloading
  the external libs.  Patch by Youhei Sakurai.

* GH#187: Now supports (only) version 5.x and later of PyPy.
  Patch by Armin Rigo.

* GH#186: Soupparser failed to process entities in Python 3.x.
  Patch by Duncan Morris.

* GH#185: Rare encoding related `TypeError` on import was fixed.
  Patch by Petr Demin.

* GH#181: Direct support for `.rnc` files in `RelaxNG()` if `rnc2rng`
  is installed.  Patch by Dirkjan Ochtman.




