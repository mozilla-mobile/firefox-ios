# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import os

from taskgraph.util.memoize import memoize


@memoize
def get_screenshots_locales():
    current_dir = os.path.dirname(os.path.realpath(__file__))
    project_dir = os.path.realpath(os.path.join(current_dir, '..', '..'))

    config = {"locales": []}

    # Check all *.lproj files as there is one per locale
    for file in os.listdir(os.path.join(project_dir, 'Client')):
        if file.endswith(".lproj"):
                config["locales"].append(file)

    # Save only the locale's name
    config["locales"] = [item.replace(".lproj", "") for item in config["locales"]]
    return sorted(config["locales"])
