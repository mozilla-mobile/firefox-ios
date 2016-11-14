#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import print_function

import json
import urlparse


def url_filter(resource):
    return "^https?://([^/]+\\.)?" + resource.replace(".", "\\.")


def unless_domain(properties):
    return ["*" + domain for domain in properties]


def create_blocklist_entry(resource, properties):
    return {"trigger": {"url-filter": url_filter(resource),
                        "load-type": ["third-party"],
                        "unless-domain": unless_domain(properties)},
            "action": {"type": "block"}}


def generate_entity_list(path="shavar-prod-lists/disconnect-entitylist.json"):
    with open(path) as fp:
        entitylist = json.load(fp)

        blocklist = []

        for name, value in entitylist.items():
            for resource in value['resources']:
                entry = create_blocklist_entry(resource, value['properties'])
                blocklist.append(entry)

        f = open('Lists/disconnect.json', 'w')
        out = json.dumps(blocklist, indent=0,
                         separators=(',', ':')).replace('\n', '')
        f.write(out)

        # Human-readable output.
        # print json.dumps(blocklist, indent=2)


def generate_blacklists(blacklist="shavar-prod-lists/disconnect-blacklist.json", entitylist="shavar-prod-lists/disconnect-entitylist.json"):
    # Generating the categorical lists requires some manual tweaking to the
    # data at the moment.

    def find_entry(entry, list_):
        for d in list_:
            if d.keys() == [entry]:
                return d

    # First, massage the existing categorical data slightly
    with open(blacklist) as fp:
        categories = json.load(fp)["categories"]
        # Remove what we know we don't care about
        del categories["Legacy Disconnect"]
        del categories["Legacy Content"]
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
    with open("shavar-prod-lists/google_mapping.json") as fp:
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

    for category in ("Advertising", "Analytics", "Social", "Content"):
        blocklist = []

        for entity in categories[category]:
            for name, domains in entity.iteritems():
                for property_, resources in domains.iteritems():
                    if name in entities:
                        props = entities[name]["properties"]
                    else:
                        prop = urlparse.urlparse(property_).netloc.split(".")
                        if prop[0] == "www":
                            prop.pop(0)
                        props = [".".join(prop)]
                    for res in resources:
                        blocklist.append(create_blocklist_entry(res, props))

        print("{cat} blacklist has {count} entries."
              .format(cat=category, count=len(blocklist)))

        with open("Lists/disconnect-{0}.json".format(category.lower()),
                  "w") as fp:
            out = json.dumps(blocklist, indent=0,
                             separators=(',', ':')).replace('\n', '')
            fp.write(out)


if __name__ == "__main__":
    # generate_entity_list()
    generate_blacklists()
