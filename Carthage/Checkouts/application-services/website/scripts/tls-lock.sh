#!/bin/sh
#
# Ensure that all registry URLs in package-lock.json use https:// scheme.
# I'm not sure why npm doesn't do this by default but it seems important
# from a security PoV...

sed -i.orig 's/"resolved": "http:\/\/registry\.npmjs\.org\//"resolved": "https:\/\/registry.npmjs.org\//' package-lock.json
rm -f package-lock.json.orig
