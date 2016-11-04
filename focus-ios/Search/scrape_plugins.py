#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from lxml import html
from lxml import etree
import copy
import json
import os
import requests
import shutil
import subprocess
import urllib

# Paths for en-US plugins included in the core Android repo.
EN_PLUGINS_FILE_URL = "https://hg.mozilla.org/releases/mozilla-aurora/raw-file/default/mobile/locales/en-US/searchplugins/%s"

# Paths for plugins in the l10n repos.
L10N_PLUGINS_FILE_URL = "https://hg.mozilla.org/releases/l10n/mozilla-aurora/%s/raw-file/default/mobile/searchplugins/%%s"

ns = { "search": "http://www.mozilla.org/2006/browser/search/" }

enTemplateCache = {}

def main():
    with open('list.json') as list:
        plugins = json.load(list)

    engines = {}

    locales = plugins["locales"]
    supportedLocales = getSupportedLocales()

    for locale in locales:
        if locale in supportedLocales:
            print("adding %s..." % locale)
        else:
            print("skipping %s" % locale)
            continue

        regions = locales[locale]
        for region in regions:
            if region == "default":
                code = locale
            else:
                language = locale.split("-")[0]
                code = ("%s-%s" % (language, region))

            engine = regions[region]["visibleDefaultEngines"][0]
            engines[code] = getTemplate(locale, engine)

    print("adding default...")
    engine = plugins["default"]["visibleDefaultEngines"][0]
    engines["default"] = getTemplate("default", engine)

    savePlist(engines)

def getTemplate(locale, engine):
    filename = engine + '.xml'

    downloadedFile = L10nScraper(locale).getFile(filename)
    if downloadedFile.getcode() == 404:
        return getEnTemplate(filename)

    if downloadedFile.getcode() != 200:
        raise Exception("Could not find %s for en-US" % filename)

    return parseTemplate(filename, downloadedFile.read())

def getEnTemplate(filename):
    if filename in enTemplateCache:
        return enTemplateCache[filename]

    downloadedFile = EnScraper().getFile(filename)
    if downloadedFile.getcode() != 200:
        raise Exception("Could not find %s for en-US" % filename)

    template = parseTemplate(filename, downloadedFile.read())
    enTemplateCache[filename] = template
    return template

def parseTemplate(filename, xml):
    plugin = etree.fromstring(xml)

    # Apply iOS-specific overlays for this engine if they are defined.
    name, _ = os.path.splitext(filename)
    engine = name.split("-")[0]
    overlay = overlayForEngine(engine)
    if overlay:
        overlay.apply(plugin)

    path = "//search:Url[@type='text/html']"
    urlElement = plugin.xpath(path, namespaces=ns)[0]
    base = urlElement.get('template')
    params = []
    for param in urlElement.getchildren():
        params.append('%s=%s' % (param.get('name'), param.get('value')))
    return base + '?' + '&'.join(params)

def getSupportedLocales():
    supportedLocales = subprocess.Popen("./get_supported_locales.swift", stdout=subprocess.PIPE).communicate()[0]
    return json.loads(supportedLocales.replace("_", "-"))

def overlayForEngine(engine):
    path = os.path.join("SearchOverlays", "%s.xml" % engine)
    if not os.path.exists(path):
        return None
    return Overlay(path)

def savePlist(engines):
    root = etree.Element('dict')
    for locale in sorted(engines.keys()):
        key = etree.Element('key')
        key.text = locale
        root.append(key)
        value = etree.Element('string')
        value.text = engines[locale]
        root.append(value)

    plist = etree.tostring(root, encoding="utf-8", pretty_print=True)
    with open("SearchEngines.plist", "w") as outfile:
        outfile.write(plist)


class Scraper:
    def pluginsFileURL(self): pass

    def getFile(self, file):
        return urllib.urlopen(self.pluginsFileURL % file)

class L10nScraper(Scraper):
    def __init__(self, locale):
        self.pluginsFileURL = L10N_PLUGINS_FILE_URL % locale

class EnScraper(Scraper):
    def __init__(self):
        self.pluginsFileURL = EN_PLUGINS_FILE_URL


class Overlay:
    def __init__(self, path):
        overlay = etree.parse(path)
        self.actions = overlay.getroot().getchildren()

    def apply(self, doc):
        for action in self.actions:
            if action.tag == "replace":
                self.replace(target=action.get("target"), replacement=action[0], doc=doc)
            elif action.tag == "append":
                self.append(parent=action.get("parent"), child=action[0], doc=doc)

    def replace(self, target, replacement, doc):
        for element in doc.xpath(target, namespaces=ns):
            replacementCopy = copy.deepcopy(replacement)
            element.getparent().replace(element, replacementCopy)

            # Try to preserve indentation.
            replacementCopy.tail = element.tail

    def append(self, parent, child, doc):
        for element in doc.xpath(parent, namespaces=ns):
            childCopy = copy.deepcopy(child)
            element.append(childCopy)

            # Try to preserve indentation.
            childCopy.tail = "\n"
            previous = childCopy.getprevious()
            if previous is not None:
                childCopy.tail = previous.tail
                prevPrevious = previous.getprevious()
                if prevPrevious is not None:
                    previous.tail = prevPrevious.tail


if __name__ == "__main__":
        main()
