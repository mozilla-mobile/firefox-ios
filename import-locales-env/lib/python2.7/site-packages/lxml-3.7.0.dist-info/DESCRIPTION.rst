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
https://github.com/lxml/lxml/tree/lxml-3.7 .
Running ``easy_install lxml==3.7bugfix`` will install
the unreleased branch state from
https://github.com/lxml/lxml/tarball/lxml-3.7#egg=lxml-3.7bugfix
as soon as a maintenance branch has been established.  Note that this
requires Cython to be installed at an appropriate version for the build.

3.7.0 (2016-12-10)
==================

Features added
--------------

* GH#217: ``XMLSyntaxError`` now behaves more like its ``SyntaxError``
  baseclass.  Patch by Philipp A.

* GH#216: ``HTMLParser()`` now supports the same ``collect_ids`` parameter
  as ``XMLParser()``.  Patch by Burak Arslan.

* GH#210: Allow specifying a serialisation method in ``xmlfile.write()``.
  Patch by Burak Arslan.

* GH#203: New option ``default_doctype`` in ``HTMLParser`` that allows
  disabling the automatic doctype creation.  Patch by Shadab Zafar.

* GH#201: Calling the method ``.set('attrname')`` without value argument
  (or ``None``) on HTML elements creates an attribute without value that
  serialises like ``<div attrname></div>``.  Patch by Daniel Holth.

* GH#197: Ignore form input fields in ``form_values()`` when they are
  marked as ``disabled`` in HTML.  Patch by Kristian Klemon.

Bugs fixed
----------

* GH#206: File name and line number were missing from XSLT error messages.
  Patch by Marcus Brinkmann.

Other changes
-------------

* Log entries no longer allow anything but plain string objects as message text
  and file name.

* ``zlib`` is included in the list of statically built libraries.




