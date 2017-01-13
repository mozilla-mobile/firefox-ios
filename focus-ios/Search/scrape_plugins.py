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
import sys
import subprocess
import urllib

# Paths for en-US plugins included in the core Android repo.
EN_PLUGINS_FILE_URL = "https://hg.mozilla.org/releases/mozilla-aurora/raw-file/default/mobile/locales/en-US/searchplugins/%s"

# Paths for plugins in the l10n repos.
L10N_PLUGINS_FILE_URL = "https://hg.mozilla.org/releases/l10n/mozilla-aurora/%s/raw-file/default/mobile/searchplugins/%%s"

# TODO: Download list from Android repo once the mobile list is in the tree.
LIST_PATH = "./list.json"

ns = { "search": "http://www.mozilla.org/2006/browser/search/" }

def main():
    # Remove and recreate the SearchPlugins directory.
    if os.path.exists("SearchPlugins"):
        shutil.rmtree("SearchPlugins")
    os.makedirs("SearchPlugins")

    with open(LIST_PATH) as list:
        plugins = json.load(list)

    engines = {}

    # Import engines from the l10n repos.
    locales = plugins["locales"]
    supportedLocales = getSupportedLocales()
    for locale in locales:
        regions = locales[locale]
        for region in regions:
            if region == "default":
                code = locale
            else:
                language = locale.split("-")[0]
                code = ("%s-%s" % (language, region))

            if code in supportedLocales:
                print("adding %s..." % code)
            else:
                print("skipping %s" % code)
                continue

            visibleEngines = regions[region]["visibleDefaultEngines"]
            downloadEngines(code, L10nScraper(locale), visibleEngines)
            engines[code] = visibleEngines

    # Import default engines from the core repo.
    print("adding defaults...")
    defaultEngines = EnScraper().getFileList()
    downloadEngines("default", EnScraper(), defaultEngines)
    engines['default'] = plugins['default']['visibleDefaultEngines']

    # Remove Bing.
    if "bing" in engines['default']: engines['default'].remove('bing')

    # Make sure fallback directories contain any skipped engines.
    verifyEngines(engines)

    # Write the list of engine names for each locale.
    writeList(engines)

def downloadEngines(locale, scraper, engines):
    directory = os.path.join("SearchPlugins", locale)
    if not os.path.exists(directory):
        os.makedirs(directory)

    # Remove Bing.
    if 'bing' in engines: engines.remove('bing')

    # Always include DuckDuckGo.
    if "duckduckgo" not in engines:
        lastEngine = '~'
        for i, engine in reversed(list(enumerate(engines))):
            if i > 0 and "duckduckgo" < engine and engine < lastEngine and not engine.startswith("google"):
                lastEngine = engine
                continue
            engines.insert(i + 1, "duckduckgo")
            break

    for engine in engines:
        file = engine + ".xml"
        path = os.path.join(directory, file)
        downloadedFile = scraper.getFile(file)
        if downloadedFile == None:
            print("  skipping: %s..." % file)
            continue

        print("  downloading: %s..." % file)
        name, extension = os.path.splitext(file)

        # Apply iOS-specific overlays for this engine if they are defined.
        if extension == ".xml":
            engine = name.split("-")[0]
            overlay = overlayForEngine(engine)
            if overlay:
                plugin = etree.parse(downloadedFile)
                overlay.apply(plugin)
                contents = etree.tostring(plugin.getroot(), encoding="utf-8", pretty_print=True)
                with open(path, "w") as outfile:
                    outfile.write(contents)
                continue

        # Otherwise, just use the downloaded file as is.
        shutil.move(downloadedFile, path)

def verifyEngines(engines):
    print("verifying engines...")
    error = False
    for locale in engines:
        dirs = [locale, locale.split('-')[0], 'default']
        dirs = map(lambda dir: os.path.join('SearchPlugins', dir), dirs)
        for engine in engines[locale]:
            file = engine + '.xml'
            if not any(os.path.exists(os.path.join(dir, file)) for dir in dirs):
                error = True
                print("  ERROR: missing engine %s for locale %s" % (engine, locale))
    if not error:
        print("  OK!")

def getSupportedLocales():
    supportedLocales = subprocess.Popen("./get_supported_locales.swift", stdout=subprocess.PIPE).communicate()[0]
    return json.loads(supportedLocales.replace("_", "-"))

def overlayForEngine(engine):
    path = os.path.join("SearchOverlays", "%s.xml" % engine)
    if not os.path.exists(path):
        return None
    return Overlay(path)

def writeList(engines):
    root = etree.Element('dict')
    for locale in sorted(engines.keys()):
        key = etree.Element('key')
        key.text = locale
        root.append(key)
        values = etree.Element('array')
        for engine in engines[locale]:
            value = etree.Element('string')
            value.text = engine
            values.append(value)
        root.append(values)

    plist = etree.tostring(root, encoding="utf-8", pretty_print=True)
    with open("SearchEngines.plist", "w") as outfile:
        outfile.write(plist)


class Scraper:
    def pluginsFileURL(self): pass

    def getFile(self, file):
        path = self.pluginsFileURL % file
        handle = urllib.urlopen(path)
        if handle.code != 200:
            return None

        result = urllib.urlretrieve(path)
        return result[0]

    def getFileList(self):
        response = requests.get(self.pluginsFileURL % '')
        if not response.ok:
            raise Exception("error: could not read plugins directory")

        lines = response.content.strip().split('\n')
        lines = map(lambda line: line.split(' ')[-1], lines)
        lines = filter(lambda f: f.endswith('.xml'), lines)
        return map(lambda f: f[:-4], lines)

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
