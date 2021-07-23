# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from itertools import islice


class ChunkingError(Exception):
    pass


def split_evenly(n, chunks):
    """Split an integer into evenly distributed list

    >>> split_evenly(7, 3)
    [3, 2, 2]

    >>> split_evenly(12, 3)
    [4, 4, 4]

    >>> split_evenly(35, 10)
    [4, 4, 4, 4, 4, 3, 3, 3, 3, 3]

    >>> split_evenly(1, 2)
    Traceback (most recent call last):
        ...
    ChunkingError: Number of chunks is greater than number

    """
    if n < chunks:
        raise ChunkingError("Number of chunks is greater than number")
    if n % chunks == 0:
        # Either we can evenly split or only 1 chunk left
        return [n // chunks] * chunks
    # otherwise the current chunk should be a bit larger
    max_size = n // chunks + 1
    return [max_size] + split_evenly(n - max_size, chunks - 1)


def chunkify(things, this_chunk, chunks):
    if this_chunk > chunks:
        raise ChunkingError("this_chunk is greater than total chunks")

    dist = split_evenly(len(things), chunks)
    start = sum(dist[:this_chunk-1])
    end = start + dist[this_chunk-1]

    try:
        return things[start:end]
    except TypeError:
        return islice(things, start, end)
