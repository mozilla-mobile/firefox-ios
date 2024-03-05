#!/bin/sh

#
# This script is executed by Xcode Cloud after it clones the repository. It only
# calls checkout.sh to pull in the blocklists.
#

(cd .. && ./checkout.sh)

