#!/usr/bin/python

import re
import sys

import git_filter_repo


class RepoFilter(git_filter_repo.RepoFilter):
    """Replace commit hashes in commit messages with a github URL
    """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
	# some commit messages included a URL, where the hash was updated by
	# the move to firefox-android, but the repo name wasn't, so we're also
	# fixing that up here.
        self._hash_re = re.compile(br'\b(https://github.com/mozilla-mobile/[a-z-]*/commit/)?([0-9a-f]{7,40})\b')

    def _translate_commit_hash(self, matchobj_or_oldhash):
        old_hash = matchobj_or_oldhash
        if not isinstance(matchobj_or_oldhash, bytes):
            old_hash = matchobj_or_oldhash.group(2)
        new_hash = super()._translate_commit_hash(old_hash)
        if new_hash == old_hash:
            # not a firefox-android commit, don't touch it
            if isinstance(matchobj_or_oldhash, bytes):
                return matchobj_or_oldhash
            # return the full match to not lose the URL
            return matchobj_or_oldhash.group(0)
        # turn the hash into a URL to avoid a dangling reference
        return b"https://github.com/mozilla-mobile/firefox-android/commit/" + old_hash


def main():
    args = git_filter_repo.FilteringOptions.parse_args(sys.argv[1:])
    RepoFilter(args).run()


if __name__ == "__main__":
    main()
