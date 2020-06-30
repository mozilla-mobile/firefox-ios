# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import print_function, unicode_literals

import os

from copy import deepcopy
from chunkify import chunkify
from math import log, ceil
from taskgraph.loader.transform import loader as base_loader

from ..screenshots_locales import get_screenshots_locales


def loader(kind, path, config, params, loaded_tasks):
    not_for_locales = config.get("not-for-locales", [])
    locales_per_chunk = config["locales-per-chunk"]

    filtered_locales = [
        locale for locale in get_screenshots_locales() if locale not in not_for_locales
    ]
    chunks, remainder = divmod(len(filtered_locales), locales_per_chunk)
    if remainder:
        # We need one last chunk to include locales in remainder
        chunks = int(chunks + 1)

    # Taskcluster sorts task names alphabetically, we need numbers to be zero-padded.
    max_number_of_digits = _get_number_of_digits(chunks)

    jobs = {
        str(this_chunk).zfill(max_number_of_digits): {
            "attributes": {
                "chunk_locales": chunkify(filtered_locales, this_chunk, chunks),
                "l10n_chunk": str(this_chunk),
            }
        }
        # Chunks starts at 1 (and not 0)
        for this_chunk in range(1, chunks + 1)
    }

    config["jobs"] = jobs

    return base_loader(kind, path, config, params, loaded_tasks)


def _get_number_of_digits(number):
    # XXX We add 1 to number because `log(100)` returns 2 instead of 3
    return int(ceil(log(number + 1, 10)))
