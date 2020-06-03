# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import absolute_import, print_function, unicode_literals

import os
import yaml

from taskgraph.util.memoize import memoize

@memoize
def get_screenshots_locales():
    current_dir = os.path.dirname(os.path.realpath(__file__))
    project_dir = os.path.realpath(os.path.join(current_dir, '..', '..'))

    with open(os.path.join(project_dir, 'l10n-screenshots-config.yml')) as f:
        config = yaml.safe_load(f)

    return config["locales"]
