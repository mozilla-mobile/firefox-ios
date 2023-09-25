#!/usr/bin/env python3

import os
import sys


version = sys.argv[1]


print("== Commits marked as cherry picked ==")
# Create a list of commits not merged directly the 118 branch
myCmd = "git log --no-merges release/v" + version + " ^release/v" + str((int(version) + 1)) + " | grep cherry |  awk '{print " " $5}' | awk '{print substr($1, 1, length($1)-1)}'"

# Clean up and put in a list
commits = os.popen(myCmd).read().split("\n")
commits = list(filter(None, commits))

for item in commits:
    # Get the originating cherrypicked branch
    val = os.popen('git branch --contains ' + item).read();

    # If there is no originating branch, we need to check manually the backport
    if not val:
        output = os.popen('git show --oneline --no-patch ' + item).read()
        print(output, end='')


print("")
print("== Commits not marked as cherry picked ==")
# Create a list of commits not merged directly the 118 branch
myCmd = "git log --no-merges release/v" + version + " ^release/v" + str((int(version) + 1)) + " | grep -v cherry"

# Clean up and put in a list
commits = os.popen(myCmd).read().split("\n")
commits = list(filter(None, commits))
exit(0)
for item in commits:
    # Get the originating cherrypicked branch
    val = os.popen('git branch --contains ' + item).read();

    # If there is no originating branch, we need to check manually the backport
    if not val:
        output = os.popen('git show --oneline --no-patch ' + item).read()
        print(output, end='')