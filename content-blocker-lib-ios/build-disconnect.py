#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import print_function

import json
import urlparse

# the list of files written out
files = []
base_dir = "../Carthage/Checkouts/shavar-prod-lists"

block_cookies_mode = False

def output_filename(category):
    action = "block-cookies" if block_cookies_mode else "block"
    return "Lists/disconnect-{0}-{1}.json".format(action ,category.lower())

def url_filter(resource):
    # Match any char except a slash with: [^/]
    return "^https?://([^/]+\\.)?" + resource.replace(".", "\\.")


def unless_domain(properties):
    return ["*" + domain for domain in properties]


def create_blocklist_entry(resource, related_domains):
    action = "block-cookies" if block_cookies_mode else "block"

    result = {"trigger": {"url-filter": url_filter(resource),
                        "load-type": ["third-party"]},
            "action": {"type": action }}

    if len(related_domains) > 0:
        result["trigger"]["unless-domain"] = unless_domain(related_domains)
    return result

def add_entry_to_blocklist(blocklist, entities, name, property_, resources):
    if not (property_.startswith("http") or property_.startswith("www")):
        return # 'dnt', 'session-replay', 'performance' are keys that are ignored
    if name in entities:
        related_domains = entities[name]["properties"]
    else:
        prop = urlparse.urlparse(property_).netloc.split(".")
        if prop[0] == "www":
            prop.pop(0)
        props = [".".join(prop)]
    for res in resources:
        if len(res) > 2:
            blocklist.append(create_blocklist_entry(res, related_domains))
        else:
            print("Found invalid resource.")

def generate_blacklists(blacklist, entitylist):
    # Generating the categorical lists requires some manual tweaking to the
    # data at the moment.

    def find_entry(entry, list_):
        for d in list_:
            if d.keys() == [entry]:
                return d

    # First, massage the existing categorical data slightly
    with open(blacklist) as fp:
        categories = json.load(fp)["categories"]
        # Move the Twitter and Facebook entries into the Social category from
        # the Disconnect category
        disconnect = categories["Disconnect"]
        del categories["Disconnect"]
        categories["Social"].append(find_entry("Facebook", disconnect))
        categories["Social"].append(find_entry("Twitter", disconnect))

    # Load the entitylist to map the whitelist entries.
    with open(entitylist) as fp:
        entities = json.load(fp)

    # Change the Google entries for the respective categories
    with open(base_dir + "/google_mapping.json") as fp:
        tweaks = json.load(fp)["categories"]
        for category in ("Advertising", "Analytics", "Social"):
            cat = categories[category]
            goog = find_entry("Google", cat) or None
            if goog is None:
                # No data exist for this category, just append
                cat.append(tweaks[category][0])
            else:
                for prop, resources in tweaks[category]["Google"].items():
                    if prop not in goog:
                        goog[prop] = resources
                        continue
                    for resource in resources:
                        if resource not in goog[prop]:
                            goog[prop].append(resource)
                    goog[prop].sort()
            cat.sort()

    for category in categories:
        blocklist = []

        for entity in categories[category]:
            for name, domains in entity.iteritems():
                for property_, resources in domains.iteritems():
                    add_entry_to_blocklist(blocklist, entities, name, property_, resources)

        print("{cat} blacklist has {count} entries."
              .format(cat=category, count=len(blocklist)))

        out_file = output_filename(category)
        files.append(out_file)
        with open(out_file, "w") as fp:
            out = json.dumps(blocklist, indent=0,
                             separators=(',', ':')).replace('\n', '')
            fp.write(out)


def format_one_rule_per_line(files):
    for name in files:
        file = open(name)
        line = file.read()
        file.close()
        line = line.replace('{"action"', '\n{"action"')
        with open(name, "w") as fp:
            fp.write(line)


import sys
import os

def help():
    print("Specify `block` or `block-cookies` as arg.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        help()
        exit(1)

    block_cookies_mode = sys.argv[1] == 'block-cookies'
    if not block_cookies_mode and sys.argv[1] != 'block':
        help()
        exit(1)
    blacklist = '../Carthage/Checkouts/shavar-prod-lists/disconnect-blacklist.json'
    entitylist =  '../Carthage/Checkouts/shavar-prod-lists/disconnect-entitylist.json'

    if not os.path.exists("Lists"):
        os.mkdir("Lists")

    generate_blacklists(blacklist, entitylist)

    # format as one action per-line, which is easier to read and diff
    format_one_rule_per_line(files)
