# Remerge: A syncable store for generic data types

The Remerge component provides a data storage mechanism. Using Remerge
has similar ergonomics to using the venerable
[JSONFile](https://mozilla.github.io/firefox-browser-architecture/text/0012-jsonfile.html)
mechanism, but with some ability to sync. It does not go as far as
being built with true CRDTs, but in exchange it is very easy and
natural to use for common use cases.

## Background/Goals/Etc

Synchronization and synchronized data types are table stakes for
client software in the modern era. Despite this, implementation of
syncing is technically challenging and often left as an
afterthought. Implementation of syncing features often relies on the
Sync team implementing a new component. This is unworkable.

The Mentat project was an attempt to solve this problem globally by
defining a storage mechanism that could sync natively and was easy to
use by client developers. Unfortunately, with the (indefinite)
"[pause](https://mail.mozilla.org/pipermail/firefox-dev/2018-September/006780.html)"
of Mentat, there's no obvious path forward for new synced data types.

After some thought, I've come up with a design that gets us some of the benefits
of Mentat with the following major benefits (compared to Mentat):

- Works on top of Sync 1.5, including interfacing with existing
  collections.  This means we don't need to throw away our existing
  server-side mechanisms or do costly migrations.
- Doesn't change the sync data model substantially. Unlike Mentat,
  which had a very ambitious data model and query language, Remerge is
  designed around normal collections of records which are "dumb" JSON
  blobs.
- Has storage which is straightforward to implement on top of SQLite.

In one of the AllHands, Lina had a presentation which defined three different
types of sync data stores.

1. Tree stores (bookmarks). The defining features of these stores are that:
    - They represent a tree.
    - They are considered corrupt if tree constraints are invalidated.
2. Log stores (history). The defining features of these stores are that:
    - Typically too large to fit in memory.
    - We expect to only sync a subset of the records in them.
3. Record stores (logins, addresses, credit cards, addons, etc)

This document describes a plan for syncing "Type 3" data stores in a generic
way, however extended to allow the following additional major features not
present in the current system:

1. Schema evolution with both forwards and backwards compatibility, with the
   ability to break compatibility gradually, avoiding breaking sync with
   versions that are still supported
2. Flexible merge logic.
3. Relatively rich data types, with the ability to add more data types over time
   without breaking old clients (which IIUC was a problem mentat had).

### Main Ideas

The high level summary of the "big ideas" behind Remerge, in very rough order of
importance, are as follows:

1. By syncing the schema, we can allow older clients to understand enough
   semantic data about the record format so that they're still able to sync and
   perform correct three way merges, even if they don't actually understand how
   to use the data that they're merging.

    See the [schema format reference](schema-format.md) for details.

2. We can allow schema evolution and forwards compatibility by storing both the
   schema version, and a cutoff version.

    See the section on [version strings](version-strings.md) for details.

3. We can add new functionality / data type support to `remerge` without
   breaking old clients by including information about the set of functionality
   the schema requires in the schema itself.

    See the section on [extending remerge](extending-remerge.md) for details.

4. We detect conflicts in a much more accurate manner by using vector clocks,
   which allows us to avoid running merge logic in far more cases than we
   currently do.

    See the section on [clocks and timestamps](clocks.md) for details.

### Intentional Limitations

Remerge comes with the following limitations, which simplify both the API and
implementation, or allow for better compatibility with sync15 or ease of use.

#### 1. Large data sets are out of scope.

For collections that expect to store many thousands of records for typical use
cases, another solution is required (we should encourage those teams to reach
out to us instead).

#### 2. No support for inter-record references.

Note: Some form of support for this may be added in a future version.

#### 3. Limited read API

The initial version will broadly only support simple `get_by_id` and `get_all`
queries.

(Note: a `get_records_with_field_value(field_name, field_value, limit)` might
also be necessary in the initial version for form autofill)

While the set of functions for this is sure to expand, a query builder API (let
alone a query language) is very much out of scope.

Because the data sets are not expected to be large, it's expected that calling
`get_all` (or using a cached version) and performing the query on the in-memory
data set is sufficient, and for cases where it's not, we can add such via fixed
functions.

#### 4. Limited write API

The initial version will broadly only support `insert`, `update`, `delete`, and
`delete_all(include_remote: bool)` functions. All storage operations should be explicit.

(Note: a function to set an individual field / subset of fields of a record
might also be necessary in the initial version for form autofill)

That said, there are no transactions, triggers, or other advanced data
manipulation features.

#### 5. No strong eventual consistency (e.g. Why not a CRDT)

Given the use of some CRDT-esque elements in this design (vector clocks, for
example), a version that was based around CRDTs would gain the propety of
strong eventual consistency (that no matter the order events occur in, the
same outcome will be produced).

We don't do this. Most sync collections would be difficult or impossible to
express as CRDTs, and it would force us to either expose a complex API, severely
limit the types of data that can be synced, or introduce a large abstraction
boundary between the actual data representation that is stored and synced, and
what the public API is (which would impose a greate deal of implementation
complexity).

Instead, Remerge records are essentially JSON blobs (that conform to a given schema).

The case where this matters is when conflict occurs. If we detect a conflict,
then we fall back to the merge algorithm described later.

#### 6. No support for custom merge code.

Several reasons for this:

- It would be a pain (to put it lightly) to expose custom merge handlers over
  the FFI.

- This would be easy to get wrong unless it was very simple and was operating on
  primitives.

- I'm not convinced it's necessary, I strongly suspect most merge handling would
  be implementing one of the strategies or data types described here.

- Changes to the custom merge handler could easily cause confusion in clients.

- Couldn't realistically do a proper 3 way merge for most cases without a lot of
  effort.

Instead we'd either expose something like this as a new data type or merge
strategy and put it behind a remerge feature (see the Extending Remerge
section), or accept remerge isn't a good fit for them (for example, if someone
wanted a custom merge handler so that they could sync something of similar
structural complexity to bookmarks).

### High level overview

At a high level, we will store a versioned schema somewhere on the server. This
describes both the record format, and how to perform merges. The goal is to
allow clients who have not fully been updated to perform merges without data
loss.

Additionally, the schema contains two version numbers. Both the schema version,
and the minimum (native schema) version a client must have to sync. These two
allow us to migrate the schema progressively, only locking out clients that are
past a certain age, while letting users with devices which are only a single
version behind sync.

In order to keep compatibility while new versions of remerge add new features,
we use an explicit list of required feature flags. A secondary list of optional
feature flags is also present, but not necessary besides to sanity-check the
schema.

The schema is typed, and contains both type information for fields, which merge
strategies to use, constraints to place on those fields during schema updates.

Locally, multiple collections are stored in a single database, and every
collection has both the local copy and mirror available, so that a 3-way-merge
may be performed.

## The Schema

The reference material for the schema has been moved into its own file.

## Clocks and Timestamps

In Remerge, we use vector clocks for conflict detection (where possible --
we support syncing with legacy collections that may be written to by naive
clients, so for collections explicitly marked as legacy, we fall back to using
modification timestamps in the case that vector clocks are not present).

Additionally, there are some cases where we use modification timestamps for
conflict *resolution*, but only after the vector clock has detected that a
conflict truly has occurred (or is unavailable, as may be the case when
interacting with legacy collections), and the schema doesn't give us a better
guideline. This is done much in the same way as the current sync system, and is
discussed in more detail in the section on merging records.

Anyway, vector clocks may be unfamiliar, see [the appendix][vector_clock_overview]
for a brief explanation on how they work if this is the case.

### Our use of Vector clocks

One of the noted downsides of vector clocks is that they tend to grow without
bound. That is, there are cases when an item is added to a vector clock (a
client that has never modified a given record does so for the fist time), but no
cases where an item is removed from one.

This seems likely to be a non-problem for us in practice. A record will need to
be changed on a given client in order for that client to add it's ID to the
clock, and in practice the number of devices remains small for most users (let
alone the number of devices which have edited a specific record, which is what
matters here).

We can also implement pruning strategies if in practice this assumption turns
out to be wrong, and to support this the `last_sync` time is recorded in the new
`client_info` meta record for this collection.

#### Client IDs

As mentioned elsewhere, we'll generate a local client ID when the database is
created. This is used for the client ID for the vector clock, and in the
`client_info` record (see the section on new metadata). There's a problem here
in that users may copy ther profile around, or have it copied by their OS (on
e.g. iOS).

Ideally we'd get some notification when that happens. If we do, we generate a new
client ID and be fine. In practice, this seems tricky to ensure. It seems likely
that we will want to add logic to handle the case that a client notices that
some other client is using it's client ID.

If this happens, it needs to take the following steps:

1. Generate a new client id.
2. Find all records that it has changed since the last sync:
    - Set their vector clock to be value of the vector clock stored in the
      mirror + `{new_client_id: old_vector_clock[old_client_id]}`. That is, it
      makes it appear that it had made the changes under the new client ID all
      along.

      JS pseudocode since rereading that explanation is confusing:

        ```js
        newVectorClock = Object.assign({}, mirrorVectorClock, {
            [newClientId]: oldVectorClock[oldClientId]
        });
        ```
This should be rare, but seems worth handling since it would be bad if the
system were fundamentally unable to handle it

Vector clocks do not help us perform merges. They only detect the cases where
merges are required. The solutions to this typically involve both using a large
number of vector clocks, and careful data format design so that merges are
always deterministic and do not depend on timestamps (See the section on 'why
not CRDTs' for a bit more on this).

Instead, remerge handles conflict resolutio is a schema-driven three way merge
algorithm, based on comparison with the most recent known server value (the
"mirror" record), and uses record modification timestamps where in cases where
an age-based comparison is required. This is discussed further in the section on
merging.

It's worth noting that a newer variant of vector clocks, known as interval tree
clocks exists, which attempts to handle the finnicky nature of client IDs.
However, these are substantially more complex and harder to understand than
vector clocks, so I don't think they make sense for our use case.

#### Legacy collections

Collections that still must interact with legacy sync clients will neither
update nor round trip vector clocks. To handle this, in the case that these are
missing, we fall back to the current conflict resolution algorithm, based on
modification timestamps. This is unfortunate, but it will allow us to behave
progressively better as more clients are changed to use this system.

## Sync and Merging

Sync works as follows.

### Sync algorithm

This assumes there are no migrations, or only compatible migrations. The case of
incompatible migrations is described in the section on migrations.

Note that the following steps must be done transactionally (that is, if any step
fails completely, no changes should be recorded).

1. We download the schema and client_info from the server.

    - If we're locked out of the schema due to it being incompatible with our
      native schema version, then we stop here and return an error to the
      caller.

2. If we need to upgrade the local version of the schema based on the version
   from the server, we do that.

    - This may change local versions of records, but we assume identical changes
      have been made other clients.

        - This is following the principal described before that the remote data
          may not be on the latest version of the schema, but the remote data
          combined with the schema is enough to bring things up to date.

3. All changed records are downloaded from the server.

4. All tombstones in the set of changed records are applied. For each tombstone:

    1. If a local modification of the record exists:

        - If deletions are preferred to local changes, then we continue as if a
          local modification does not exist, deleting the record. (see step 4.2)

        - If updates are preferred to deletions, then we will resolve in favor
          of undeleting the tombstone.

    2. If a local record exists, but without any modifications, then we forward
       it and the mirror to the incoming tombstone.

    3. Incoming tombstones that we have never seen are persisted (in order to
       prevent them from being undeleted)

        - It's possible we will want to consider expiring these eventually,
          however such functionality is easy to add in a future update.

5. For each non-tombstone record:

    1. If the record is not valid under the schema:

        - If the most recent schema version is our native schema version, delete
          the record. XXX this is dodgy since we don't know that our schema is
          actually the latest, we probably want to just always skip for now
          until we can do transactional schema / data updates.

        - Otherwise, assume we're wrong and that someone else will clean it up,
          and treat it as an unchanged server record (E.g. if we have local
          changes, we'll overwrite them, otherwise we'll ignore)

    2. If we have no local record with the same guid, then we search for
       duplicates using the schema's dedupe_on.

        - If there is a duplicate, then we mark that we need to change the
          duplicate record's id to the new ID, and proceed as if we had a
          local record with this ID (and a mirror with it, if the duplicate
          had a mirror record).

    3. If the incoming record is not in conflict with our local record (see
       the section on vector clocks for how we determine conflict), then we
       forward the mirror and local records to the incoming record.

    4. If the incoming record *is* in conflict with our local record, then we
       take one of the following steps:

        1. If the local record is a tombstone and the collection is set to
           prefer deletions, we resolve in favor of the local tombstone.

            - Note that this still involves the conflict check -- tombstones
              still have clocks.

        2. If the local record is a tombstone and the collection is set to
           prefer updates, we forward the local and mirror to the incoming
           remote record.

        3. If we don't have a mirror record, we need to perform a two way merge.

        4. If we have a mirror record, and the incoming record is a descendent
           of the mirror, then we can perform a three way merge correctly. This
           is likely to be the most common case.

        5. If we have a mirror record, and the incoming record is in conflict
           with the mirror record, then we should either

            1. For non-legacy collections, discard the record.

                - This should never happen unless the client that wrote the record
                  has a bug. Otherwise, it would perform a merge with server before
                  uploading the record.

                - Note that we wipe the mirror when node reassignment/password reset
                  occur, so that case doesn't apply here.

            2. For legacy collections, which could have had the vector clock wiped
               by a legacy client, assume this is what has happened, and do a three
               way merge.

    5. If we performed a two or three way merge, and the outcome of the merge
       indicates that we must duplicate the record, then

        1. We create a new local record with identical contents (but a new ID, and
           fresh vector clock) to the current local version.

        2. Then replacing the current local and mirror with the incoming record.

    6. All new and locally changed records (including records that were not
       resolved by forwarding the local and mirror versions to the incoming
       record) must be uploaded as part of this sync.

        - Before uploading the records, we validate them against the schema. If
          validation fails, we record telemetry, and only sync the records which
          pass validation.
            - Records which aren't synced should be flagged as such (XXX: flesh this out)
            - This telemetry should be monitored, as it indicates a bug.

    7. Upon completing the upload, record the last sync time for this collection,
       and commit any changes.

        - This, unfortunately, ignores the case where the upload was split over
          multiple batches, and the first batch succeeded, but the subsequent
          batch failed. I'm not sure this is possible to handle sanely... The
          fact that this system is not intended for collections which have so
          many records that this is an issue helps, although in practice there
          will be edge-case users who do have this many records.

        - More worrying, this ignores the case where we succesfully commit
          batches, but fail to commit the database transaction locally.

        - In both cases, the records we uploaded will be strict descendents of
          our local changes, however the strategy of detecting duplicate client
          ids above assumes that if a server write occurs with our client id,
          then that means our client ID needs to change. This is not ideal.

### Merging a record

This depends on the data type and merge strategy selected.

Before performing the two or three-way merges, we perform compatible schema
migrations (filling in missing default values, etc) on all input records. This
is not treated as changing the record in a material way (it does not effect its
value in it's vector clock, or it's sync_status).

#### Three way merge algorithm

The input to this is the schema, the local, (incoming) remote, and mirror records.

All records also have their modification timestamps.

1. The local record is compared to the mirror record to produce the "local delta":
    - For each field in the record, we either have `None` (no change), or
      `Some<new value>` indicating the local record has a change not present in the mirror.

2. The remote record is compared to the mirror record to produce the "incoming delta":
    - For each field in the record, we either have `None` (no change), or
      `Some<new value>` indicating the remote record has a change not present in the mirror.
      - If the field is numeric and has bounds, perform bounds checks here.
          - For `if_out_of_bounds: "clamp"`, clamp both the new value and the
            mirror, and check them once again against each-other.
          - For `if_out_of_bounds: "ignore"`, if the new value would bring
            the field out of bounds, ignore it.

3. A "merged delta" is produced as followed:

    1. For any change, if it was modified in only one of the two deltas and is
       not part of a composite field, copy it into the merged delta.

    2. For each composite field containing one or more changed non-deprecated
       sub-fields:

        - If the composite root has `prefer_remote`, then prefer
          remote for all members of the composite.

        - If the composite root has `take_newest`, then copy the
          fields in the composite from whichever has been modified more recently
          (as determined by modification timestamps) between the local and
          incoming remote records.
            - Note that we're copying from the records, not from the deltas.

        - If the composite root has `take_min` or
          `take_max` as it's merge strategy, then compare the values
          of the composite root in the local and remote records numerically, and
          copy all fields in the composite from the winner to the merged delta.

    3. For remaining (non-composite) fields in both the "local delta" and
       "incoming delta",

        - For fields with the `take_newest`, `prefer_remote`, `duplicate`,
          `take_min`, `take_max`, `take_sum`, `prefer_false`, `prefer_true`
          strategy, follow the description listed in the schema format document
          under "Merge Strategies".
        - If the field is an `untyped_map`: performs a similar operation to the 3WM
          where deltas are created, and each field is merged by `take_newest`.
            - If `prefer_deletions` is true, then if one field is set to the
              tombstone value, delete it.
            - This is a little hand-wavey, but seems sufficiently specified,
              esp. given that we aren't planning on implementing it immediately.
        - If the field is a `record_set`:
            - The set difference is computed between the local and mirror
            - The set difference is computed between the incoming and mirror
            - The new mirror is the `old_mirror UNION (local - mirror) UNION (remote - mirror)`
            - In the case of conflict (a new or changed record present in both local or mirror),
              the newer value is taken.
            - Note: Deletions (from the set) are stored as explicit tombstones,
              and preferred over modificatons iff. `prefer_deletions` is true.
            - This is a little hand-wavey, but seems sufficiently specified,
              esp. given that we aren't planning on implementing it immediately.

4. The "merged delta" is applied to the mirror record to produce the new local
   record which will be uploaded to the server, and become the next mirror.

    - This record will have a vector clock that is a descendent of the local,
      mirror, and incoming remote clocks.

#### Two way merge algorithm

Two-way merges are not ideal. They are performed only if we don't have a mirror.
They're intended to do as little damage as possible

The input to this is the schema, the local, and incoming remote records.

1. A delta is computed between the local and incoming remote records, in
   a similar manner to the three-way-merge case. This is known as "the delta".

2. A merged record ("the merged record") is created which starts with all values
   from the local record not present in "the delta"

    - It doesn't matter if you take from local or remote here, since
      these are the fields that we just determined were equal.

3. For each composite field containing one or more non-deprecated subfields
   present in "the delta": the merge is performed roughly the same as the 3WM
   case.

    - If the composite root has `prefer_remote`, then prefer
      remote for all members of the composite.

    - If the composite root has `take_newest`, then copy the fields
      in the composite from whichever has been modified more recently (as
      determined by modification timestamps) between the local and incoming
      remote records into "the merged record".

        - Note that we're copying from the records, not from the deltas.

    - If the composite root has `take_min` or `take_max` as it's merge strategy,
      then compare the values of the composite root in the local and remote
      records numerically, and copy all fields in the composite from the winner
      to "the merged record".

4. For remaining (non-composite) fields present in "the delta",
   "incoming delta", Store the result of the following in "the merged record":

    - For fields with the `take_newest`, `prefer_remote`, `duplicate`,
      `take_min`, `take_max`, `take_sum`, `prefer_false`, `prefer_true`, and
      `own_guid` strategy, follow the description listed in the schema format
      document under "Merge Strategies", noting that this is the two way merge
      case.

    - For `untyped_map`: The maps are merged directly, breaking ties in favor of
      the more recently modified.
        - if `prefer_deletions` is true, any field represented by a tombstone in
          either side is a tombstone in the output

    - For `record_set`:
        - The result is the set union of the two, with deletions preferred if
          `prefer_deletion` is true

5. The "merged delta" is applied to the mirror record to produce the new mirror
   record which will be uploaded to the server.

    - This record will have a vector clock that is a descendent of the local,
      mirror, and incoming remote clocks.

## New metadata records:

Some additional per-collection meta-information is required to make remerge
work.

They are stored at `meta-$collection_name/blah`. This doesn't allow for
transactional updates at the same time as the records, but in practice so long
as the schema is always uploaded prior to uploading the records, this should be
fine.

TODO: should this be `meta/$collection_name:blah` or similar?

#### `meta-$collection_name/schema`

This stores the most recent schema record. See [the schema format](schema-format.md)
reference for detailed information on its layout.

#### `meta-$collection_name/client_info`

Information about clients. An object with a single field currently, but possibly
more in the future (the library must make an effort to not drop fields it does
not understand when updating this record). The only field is `"clients"`, which
is an array of records, each with the following properties

- `"id"`: A unique ID generated on DB creation. Unrelated to any sort of current
  client ID. Discussed in the section on counters/consistency. This is a string.

    - It's illegal for this to be duplicated. If that happens, the `client_info`
      record is considered corrupted and is discarded.

- `"native_schema_version"`: This clients "native" schema version for this collection.
    - This is a semver version string.
    - This is the latest version it was told to use locally, even if in practice
      it uses a more up to date schema it fetched. This is effectively the
      version that the code adding records understands

- `"local_schema_version"`: The latest version of the schema that this client
  understands.
    - This is also a semver version string.

- `"last_sync"`: The most recent X-Weave-Timestamp (as returned by e.g. the
  fetch to `info/collections` we do before the sync or something). This is for
  expiring records from this list.

## Migrations

There are several ways you might want to do to evolve your schema, but they boil
down to two types:

Changes that have a migration path (compatible migrations), and those that do
not (incompatible migrations).

Remerge attempts to make the 2nd rare enough that you don't have to ever do it.
Eventually it will probably support it better, but that's being deferred for
future work.

### A note on version strings/numbers

I've opted to go for semver strings in basically all cases where it's a string
that a developer would write. This is nice and familiar, and helps us out a lot
in the case of 'prerelease' versions, but there are several cases where it
doesn't make sense, or isn't enough:

- The version of remerge itself, where we may add features (for example, new
  data types) to the library. We avoid using version numbers at all here, by
  specifying the feature dependencies explicitly, which is more flexible anyway.
  See the section on extending remerge for more details.

- Locking out old clients. Ideally, you could do migrations in slowly, in
  multiple steps:

    For example, if you want to make a new mandatory field, in version X you
    start populating it, then once enough users are on X, you release a
    version Y that makes it mandatory, but locks out users who have not yet
    reached X.

    Similarly for field removal, although our design handles that more
    explicitly and generally with the `deprecated` flag on fields.

    This is more or less the reason that we never change the version number
    in meta/global. It immediately impacts every unreleased version.

For both of these, we distinguish between the `current` version, and the `required`.

This is how the two are related:

- The current version must always be greater or the same than the required version
  for the client imposing the restriction. It's nonsensical otherwise.

- The required version must be semver compatible with the "current" version, and
  by default it is the smallest version that is semver-compatible with the
  current version

This is to say, if you add a new optional "foobar" field to your record in
"0.1.2", once "0.1.2" is everywhere, you can make it mandatory in a new "0.1.3",
which is listed as requiring "0.1.2".

This has the downside of... not really being what semver means at all. So I'm
open to suggestions for alternatives.

#### Native, local, and remote versions

There's another complication here, and that's the distinction between native, local,
and remote versions.

- The "remote" schema is any schema from the server, but almost always we use it
  to mean the latest schema version.
- The "native" schema version is the version that the client would be using if it
  never synced a new schema down from the server.
- The "local" schema version is the version the client actually uses. Initially
  it's the same as the native version, and if the client syncs, and sees a
  compatible 'remote' schema, then it will use the remote schema as it's new local
  schema.

Critically, the `required` schema check (described above) is performed against the
*native* schema version, and *not* the local schema version. This is required for
the system to actually lock out older clients -- otherwise they'd just confuse
themselves (in practice they should still be locked out -- we will need to make
sure we validate all records we're about to upload against the remote schema,
but this should allow them to avoid wasting a great deal of effort and possibly
reporting error telemetry or something).

Anyway, the way this will work is that if a client's *native* (**not** local)
schema version falls behind the required version, it will stop syncing.

### Semver-compatible migrations (for shipping code)

There are two categories here: Either `dedupe_on` is unchanged/relaxed, or
additional constraints are added.

Most of the time, the server data does not need to change here. The combination
of the new schema with the data the server has (which will be semver-compatible
with the new data -- or else you need to read the next section) should be enough
when combined to give all clients (who are capable of understanding the schema)
identical results.

However, we also allow adding additional constraints to `dedupe_on`. In this case,
some records may now be duplicates of existing records. Failing to fix these may
result in different clients deciding one record or another is the canonical record,
and it's not great if they disagree, so we fix it up when uploading the schema.

#### Algorithm for increasing `dedupe_on` strictness

The client uploading the schema with the new dedupe_on restriction performs the
following steps.

1. Find all combinations of records that are now considered duplicated.
    - Note that this isn't a set of pairs, it's a set of lists, e.g. changing
      `dedupe_on` could could cause any number of records to be unified.

2. For each list of records containing 2 or more records:
    1. Take the most recently modified record, and delete (uploading tombstones)
       for all others.
        - XXX It's not clear what else we should do here. Sort by modification
          date and

    2. Merge them front to back using two_way_merge until only a
      single record remains.

        - XXX: Or should we just take the one with the highest update_counter outright?

    3. The result will have the ID of the first record in the list, and will
      have a prev_id of the 2nd record.

    4. Each subsequent record will be recorded as a tombstone with a prev_id of
      the record following it (except for the last record, which will have nothing).

    For example, to merge `[a, b, c, d]`, payload of `a` will be `merge(merge(merge(a, b), c), d)`. We'd then upload (records equivalent to after adding the rest of the bso fields and encrypting)

    ```json
    [
        { "id": "a", "prev_id": "b", "payload": "see above" },
        { "id": "b", "prev_id": "c", "payload": { "deleted": true } },
        { "id": "c", "prev_id": "d", "payload": { "deleted": true } },
        { "id": "d", "payload": { "deleted": true } }
    ]
    ```

3. Upload the outgoing records and (on success) commit the changes locally.

### Semver-incompatible migrations

A lot of thought has been given to allowing evolution of the schema such that
these are not frequently required. Most of the time you should be able to
either deprecate fields, or move through a compatible upgrade path and block
out the old data by using `required_version`.

However, some of the time, outright breaking schema may be unavoidable.

Fundamentally, this will probably look like our API requiring that for a
semver-major change, the code either explicitly migrating all the records (e.g.
give them a list of the old records, get the new ones back), or very explicitly
saying that the old records should be deleted.

There are a few ways to do this in the API, I won't bikeshed that here since
they aren't super important.

The big concern here is that it means that now all records on the server must go,
and be replaced. This is very unlikely to lead to happy servers, even if the
record counts are small. Instead, what I propose is as follows:

1. If the user explicitly syncs, we do the full migration right away. The danger
   here is automatic syncs, not explicit ones. We will need to adjust the API to
   allow indicating this.

2. Otherwise, use a variant of our bookmark repair throttling logic:

    - There's an N% (for N around, IDK, 10) chance every day that a given
      client does the full sync/upgrade routine.

    - If, after M days of being updated, none of the clients have done this,
      just go for it.

    - TODO: discuss this with ops for how aggressive seems sane here.


## Extending Remerge

The initial version of Remerge will be missing several things we expect to need
in the future, but won't need for simple datatypes. Adding these cannot be a
breaking change, or Remerge is likely to never be very useful.

When a new data type or property is added to Remerge which some (but not all)
schemas may use, we also come up with a short identifier string. Any schemas
that use this feature then must specify it in the `remerge_features` property.
Adding a new entry to the `remerge_features` will lock out clients if their
version of Remerge does not support this feature. See
[the first example][required-feature-example] for an example.

Some features may be used by a schema, but in such a way that legacy clients can
still do the right thing. The motivating example here is allowing a new optional
field of some data type where it's fine for legacy clients to just ignore but
round-trip it. In this case, specifying it in `optional_remerge_features` allows
this behavior. See [the second example][optional-feature-example] for an example.

##### Example 1: A `compression` Remerge feature
[required-feature-example]: #example-1-a-compression-remerge-feature

Consider adding support for transparently compressing records before (encrypting
and) uploading them to the server.

This is a change where old clients will be completely unable to comprehend new
records, which means that, naively, unless careful coordination is performed,
this sort of change can not be done without locking out many clients.

However, we can avoid that problem with Remerge using `remerge_features`:

1. We implement support for compression in this way which can be turned on by
   specifying `compressed: true` in the schema.
2. We add "compression" to Remerge's internal static list of supported features,
   and require any schema that uses `compressed: true` to specify `compression` in
   `remerge_features`.
3. Then, collections that wish to have compression enabled just need to ensure
   that every version they consider "supported" bundles a Remerge library
   which understands the `compression` feature before (e.g. the Remerge code
   adding the `compression` feature must ride the trains before it's used).

**Note**: There are a lot of devils in the details here if we actually wanted to
support compression in this matter, this is just an example of the sort of
change that seems impossible to add support for after the fact.

##### Example 2: A new data type
[optional-feature-example]: #example-2-a-new-data-type

The usage implied in example 1 has two major drawbacks:

1. Code that might not gotten nightly / beta testing (despite riding the trains)
   is suddenly enabled remotely all at once.

2. For the common case where a feature defines a new Remerge datatype, as long
   as the field is optional (not part of a composite), and that clients
   could simply round trip it (e.g. treat it as an opaque 'prefer_remote' blob
   of data).

In practice number 1 seems unlikely to be an issue, as a new (required) feature
would either be motivated by some new collection wanting to use it, or it would
come with a breaking change anyway.

Number 2 can be avoided by using the `optional_remerge_features` property:

Note: the motivating example here is a bit more nebulous than the above, despite
the fact that it's probably the more likely case.

Lets say we're adding support for a `binary_blob` type to represent a small
optional image (like a favicon), which it represnts as a string that's
guaranteed to parse as base64 (Note: this probably wouldn't be useful, but
that's not the point).

1. Remerge implements support for this under the "binary_blob" feature.
2. The collection updates its schema to have:
    - Both `"remerge_features": ["binary_blob"]` and `"optional_remerge_features": ["binary_blob"]`
    - A new optional `favicon` field, which is optional and has type `binary_blob`.
3.

## Future Work

To be explicit, the following is deferred as future design work.

1. Detecting and deleting corrupt server records.
    - Instead, we just ignore them. This is probably bad.

2. References to other elements
    - This was a big part of the complexity in the previous version of the spec,
      and it's not totally clear that it's actually useful. Usually either
      another identifier exists (possibly whatever that type is deduped on)

3. Enumerations and fields that are mutually exclusive with other fields.
    - Exclusive fields are ecessary to model the `formSubmitURL` xor `httpRealm`
      in logins.

    - Enum-esque types, which could more or less be modeled as 'sets of
      exculsive fields where which fields are active is controlled by some
      `type` value'...

4. Support for nested objects of some kind.
    - This probably just looks like:
        - Allowing `path.to.prop` in the `name` field.
        - Coming up with the restrictions (e.g. the first segment can't already
          be a field `name` or `local_name`, all segments must follow the rules
          for names, etc)
        - ...
    - If we need addresses and credit card engine support as part of form
      autofill, we need this.

5. Properly handling when `dedupe_on` strictness is increased in a new version
   of the schema.

    - It's not clear what the actual right thing to do is, but 'delete all
      duplicates except the most recently modified' seems too risky.

6. More broadly: How/when to handle when a schema upgrade tightens constraints.
    - For example, numbers can be clamped, for now the plan is to just check on
      insert/update/sync...
    - We should at least do this when the native schema is upgraded, but we want
      to be careful to ensure it doesn't cause us to ignore incoming changes to
      those fields when we sync next.

7. Storing multiple collections in the same database.
    - Initially I had thought this was desirable, but the locking issues that
      have been cause by places make me much less sure about this, so I'm
      deferring it. It also simplifies the implementation.

### Features Deferred for after initial implementation

These are designed and specced, and I think they're very important for remerge
to actually be useful, but

1. The `record_set` type.
2. TODO: What else? There's probably a lot we could cut just to support form
   autofill, but if "everything but what form autofill needs" is cut, this would
   not be a very useful system.

## Appendix 1: Vector clock overview
[vector_clock_overview]: #appendix-1-vector-clock-overview

Feel free to skip this if you know how these work.

The goal of a vector clock is basically to let us detect the difference between
stale and conflicting data, which is something we have no ability to detect
currently.

Despite it's name, it is not a vector, and does not measure time. It is
basically a `HashMap<ClientId, u64>`, where ClientId is something like the local
client id generated by each client upon database creation, and the u64 is a
per-client change counter.

Wherever a client makes a change to some item (where item may be a record, a
field, etc), it increments it's current change counter, and sets the value
stored in the clock for it's ID to the current value of the change counter.

This lets you easily tell if one version of a record is an ancestor of another:
if record A's clock has an entry for every client in record B's clock, and they
all have the same value or higher, then record B is just a previous version of
record A, and vice versa. If neither is strictly greater than the other, then
a conflict has occurred.

See the following resources for more background, if desired:

- http://basho.com/posts/technical/why-vector-clocks-are-easy/
- http://basho.com/posts/technical/why-vector-clocks-are-hard/
- https://www.datastax.com/dev/blog/why-cassandra-doesnt-need-vector-clocks
- https://en.wikipedia.org/wiki/Vector_clock
