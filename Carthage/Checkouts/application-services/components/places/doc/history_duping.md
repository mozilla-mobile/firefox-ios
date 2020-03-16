# History duping

In a perfect world, history would de-dupe like other collections - if we see
an incoming record that's a dupe of what we have locally, we'd just change the
ID of the item we have to the incoming ID, possibly uploading a tombstone for
the ID we previously had.

However, history is a little special - the ID for records is the GUID, but
the logical ID is the URL - so there's no reason we can't have multiple
GUIDs all of which refer to the same URL - and indeed, this is what can happen
with existing clients.

If we took this same approach for history, we could end up with what the user
perceives as data-loss. Consider:

* client DESKTOP1 1000 visits for `{guid: "A", url: "http://example.com"}` - it
  uploads 20 of them.

* client RUST - this rust implementation - comes along and happily takes
  `guid="A"` and the 20 records.

* client DESKTOP2 has 500 visits for `{guid: "B", url: "http://example.com"}` -
  it uploads 20 of them.

* client RUST syncs again, finds `guid="B"` as a dupe of the local `guid="A"`,
  but note that it *does not* have the complete history from either DESKTOP1
  or DESKTOP2

If it tries to merge these into a single guid, then whatever action it takes
means that either DESKTOP1 or DESKTOP2 will lose all visits for that URL other
than the 20 it uploaded.

Therefore, the rust implementation takes the following approach:

* If there's an incoming history record for a URL that is yet to be synced
  locally, we change the guid to the incoming one and sync as normal.

* If there's an incoming history record for a URL that has been synced locally,
  we continue to use our existing guid - however, we do apply the incoming
  visits, and, if necessary, re-upload our guid after applying these visits -
  in other words, we *merge* these records, but leave the initial records
  alone.
