# Schema format

The remerge schema format is canonically YAML (Previously it was JSON, but it
seems extremely likely that comments would be valuable).

## Top level properties

As of the current version, it contains the following fields:

- `version`: Required semver version string. This schema's version number.

- `required_version`: Optional semver version string. The "native version" that
    remote clients must support in order to attempt to merge this schema.

    By default, this defaults to the lowest version that is still
    semver-compatible with `version`.

- `remerge_features`: A list of strings, the set of remerge features (see
    rfc.md) this schema uses that must be supported in order for a client not to
    be locked out.

    This must be specified if any functionality added in a remerge feature is
    allowed to be used.

    - **Caveat**: Using a new feature will lock out clients that do not have a
        version of `remerge` which understands that feature unless it's explicitly
        present in `optional_remerge_features` as well.

        Developers using `remerge`, unless they would be locking out
        old clients anyway (e.g. during initial development, or whatever).

- `optional_remerge_features`: A list of strings. If you specify
  `remerge_features`, this must be specified as well, even if it's empty.

    Every string in this list must also be present in remerge_features, and must
    pass the following test:

    1. If the feature is a new datatype, any fields which use that datatype must
       be optional and not part of a composite.
    2. Otherwise, is an error for the feature to be listed as optional.
        - *Note*: In the future, it's likely that certain new features will be
          allowed to appear in this list, in which case this documentation
          should be updated.

- `legacy`: Optional bool (defaults to false). Is this a collection that will be
  written to by non-remerge clients?

  This currently adds the following restrictions:

    - A single `own_guid` field must be present in `fields`.
    - XXX: What else?

- `fields`: An array of field records. See [Field records](field_records) for details.

- `dedupe_on`: Optional. Array of strings (defaults to `[]`). Each string must
  reference the name of an item in `fields`.

## Field records
[field_records]: #field-records

Each entry in fields has the following properties:

- `name`: Required string: The fields name. It is an error if another field has
  the same `name` or `local_name` as this name. The following restrictions apply
  to field names:

    - Field names must be non-empty.

    - Field names not be longer than 64 bytes/characters (the restriction below
        means bytes and characters are equivalent here)

    - Field names must only use the following characters: `[a-zA-Z0-9_-$]`.

        - This is to allow the possibility that a future version of remerge will
        allow you to reference properties in nested objects like `foo.bar`.

    - Field `name`s should not change (this is the name of the field on the
      server). Renaming a field conceptually can be done by specifying a
      `local_name`.

- `local_name`: Optional string, used to rename fields, defaults to `name`. Only
  the *native* schema's `local_name` values are ever used, since that's what
  calling code understands.

  - On writing to/reading from the DB, the `local_name` fields in the local
    version's native schema are mapped to `name` (for writes into the DB) or
    vice versa (for reads).

  - It is not a schema incompatible change to change a `local_name` (however a
    schema version bump is required to ensure that the mapping of `version` to
    `schema data` is unique), however it is a mistake if a `local_name` (or
    `name`) collides with any `local_name` or `name` that has been active in
    the past, however this is not currently checked.

  - The same identifier restrictions exist as with `name` (non-empty, `a-zA-Z0-9_-$`, )

  - It's an error if this `local_name` collides with any other `local_name` or
    `name`.

  - It is a mistake if a `local_name` (or `name`) collides with any
    `local_name` or `name` that has been active in the past, however this is
    not currently checked.

- `type`: Required string. The type of the field. See the section
    titled Field Types for the list of field types.

- `merge`: The merge strategy to use. Must be one of the merge strategies
   listed in the section on merge strategies.

   Note that not all `type`s support all `merge` strategies. In fact, none do.
   Additionally, some types (`own_guid`, `record_set`, and `untyped_map`) forbid
   the use of a merge strategy. Be sure to read the `Restrictions` section on
   any field you use.

   You also may not specify a merge strategy and a composite root.

- `composite_root`: In place of a `merge` strategy, all types that do not
   specifically forbid it (Note: many do) may specify `composite_root` to
   indicate that they are part of a composite, which is a string that speficies
   the root of the composite.

- `required`: Whether or not the field is required.

- `deprecated`: Indicates that the field will be ignored for the purposes of
   merging and validation. It is illegal for a type to be both `deprecated` and
   `required`.

- `change_preference`: Optional string, one of the following values. Used to
   help disambiguate problems during a conflict.

    - `"missing"`: In the case of two conflicting changes, if one of the
      changes removes the value *or* resets it to the default value provided
      for that field (if any), then that change will be taken.

    - `"present"`: In the case of two conflicting changes, if one of the
      changes removes the value *or* resets it to the default value provided
      for that field (if any), then that change will be discarded.

    - These are used prior to application of the merge strategy, see the section
      describing the `sync` algorithm for details.

Additionally many types contain a `default` value, which is discussed in the
section on the relevant record type, and in the RFC's section on the merge
algorithm (Merging a record). These are applied both to incoming items that are
missing it, and to items inserted locally that do not have it.

Some types have additional options (most types support providing a `default`
value too, for example). See below for specifics.

## `untyped`

Indicates that this field can contain any type of item representable using JSON.

Untyped data may use the following merge strategies:

- `take_newest`
- `prefer_remote`
- `duplicate`

## `text`

Indicates that this field contains text.

Text may use the following merge strategies:

- `take_newest`
- `prefer_remote`
- `duplicate`

### Options

- `default`: Optional default value string.

## `url`

Indicates that this field contains a URL.

Urls are equivalent to `text` in most ways, except that attempts to assign
invalid URLs to them are prevented, and they are guaranteed to be canonicalized
to a punycoded/percent-encoded format. (Note: canonicalization happens
transparently during update and insert)

URLs may use the following merge strategies:

- `take_newest`
- `prefer_remote`
- `duplicate`

### Options

- `is_origin`: Optional bool to indicate that this field only stores
  origins, not full URLs. A URL that contains information besides the
  origin (e.g. username, password, path, query or fragment) will be
  rejected for this field. Defaults to false.

- `default`: Optional default value.

## `real`

Indicates that this field is numeric. Reals are 64 bit floats, but NaN is
forbidden.

Numbers may use the following merge strategies:

- `take_newest`
- `prefer_remote`
- `duplicate`
- `take_min`
- `take_max`
- `take_sum`

### Options

- `default`: Optional default value. Must be a number, and must be between `min`
  and `max` if they are specified.

- `min`: Optional number specifying an (inclusive) minimum value for this field.
  If specified, the field must also contain the `if_out_of_bounds` option.

- `max`: Optional number specifying an (inclusive) minimum value for this field.
  If specified, must contain the `if_out_of_bounds` option.

- `if_out_of_bounds`: Optional string. Required if `max` or `min` are specified.
    - `"discard"`: Changes that move this value outside the range specified by
      min/max are discarded.
    - `"clamp"`: Changes are clamped between `min` and `max`

### Restrictions

- May not be part of `dedupe_on`:
    - We could loosen this to only apply for `take_sum` or bounding by `clamp`,
      and maybe a couple others, but we probably want to discourage people from
      using numeric keys for things.
- `max` may not be specified on a `take_sum` value.
- `min` and `max` must be finite. They may not be NaN or +/- infinity.
- `default` must be between `min` and `max`.
- `min` must be less than `max`.

## `integer`

Indicates that this field is an integer. Integers are equivalent to numbers
except they are represented as 64-bit signed integers.

These have all the same options and restrictions as `real`, but using 64
bit integers.

## `timestamp`

Indicates that this field is a timestamp. Timestamps are stored as integer
milliseconds since 1970.

Timestamps automatically forbid unreasonable values, such as

- Values before the release of the first browser.
- Values from the future
    - XXX Probably will need a little wiggleroom here.
    - Maybe only throw out values from more than a week in the future?

Timestamps may use the following merge strategies.

- `take_newest`
- `prefer_remote`
- `take_min`
- `take_max`

### Options

- `semantic`: Optional string. Indicates that this timestamp is a special type
  of timestamp that's automatically managed by remerge.

    - `"updated_at"`: Indicates that this timestamp should store
      a modification timestamp. If this schema is synced to older
      devices, they'll start doing the right thing here too.

      Only one field per record may have this semantic.

      If this semantic is used, the merge strategy must be `take_max`.

    - `"created_at"`: Indicates that this timestamp stores the
      creation date of the record.

      If this semantic is used, the merge strategy must be `take_min`.

    - **Note**: The reason these are fields and not simply built-in to every
      record is so that they may be used as composite roots, and for
      compatibility with legacy collections.

- `default`: Default value for the timestamp. Must either be an integer, or the
  string "now", which indicates that we'll use the current time.

### Restrictions

- Only one field per record may have the `updated_at` semantic
- Timestamps may not be part of `dedupe_on`.
- Timestamps with the `created_at` semantic must use the `take_min` merge strategy.
- Timestamps with the `updated_at` semantic must use the `take_max` merge strategy.

## `boolean`

Indicates that this field is a boolean flag.

Boolean values may use the following merge strategies:

- `take_newest`
- `prefer_remote`
- `duplicate`
- `prefer_true`
- `prefer_false`

### Options

- `default`: Optional default value. If provided, must be true or false.

## `own_guid`

Indicates that this field should be used to store the record's own guid.

This means the field is not separately stored on the server or in the database,
and instead is populated before returning to the record in APIs for querying
records.

### Options

- `auto`: Optional boolean, defaults to true. Means an ID should be
  automatically assigned during insertion if not present.

### Restrictions

- It's an error to use `own_guid` in a schema's `dedupe_on`.
- `own_guid` fields may not specify a merge strategy.
- `own_guid` fields may not be part of a composite.
- It's an error to have more than one `own_guid`.

## `untyped`

This is an unstructured JSON payload that can have any value.

May use the following conflict strategies:

- `take_newest`
- `prefer_remote`
- `duplicate`

### Options

- `default`: Optional default value, can take any valid JSON value.

## `untyped_map`

**Note**: This is a planned feature and will not be implemented in the initial
version.

Indicates that this field stores a dictionary of key value pairs which
should be merged individually. It's effectively for storing and merging
a user defined JSON objects.

This does not take a merge strategy parameter, because it implies one
itself. If you would like to use a different merge strategy for
json-like data, then `untyped` is available.

The map supports deletions. When you write to it, if your write is
missing keys that are currently present in (the local version of) the
map, they are assumed to be deleted. If necessary, this means you may
need to be sure a sync has not occurred since your last read in order
to avoid discarding remotely added data.

### Options

- `prefer_deletions`: Optional (default to false). Indicates whether updates to a
  field, or deletions of that field win in the case of conflict. If true, then
  deletions always win, even if they are older. If false, then the last write
  wins.
- `default`: Optional default value. If provided, must a JSON object

### Restrictions

- It's an error to use `untyped_map` in a schema's `dedupe_on`.
- `untyped_map` fields may not specify a merge strategy.
- `untyped_map` fields may not be part of a composite.

## `record_set`

**Note**: This is a planned feature and will not be implemented in the initial version.

A unordered set of JSON records. Records within the set will not be
merged, however the set itself will be.

This does not take a merge strategy parameter, because it implies one
itself.

The id_key is the string key that is used test members of this set
for uniqueness. Two members with the same value for their id_key are
considered identical. This is typically some UUID string you generate in
your application, but could also be something like a URL or origin.

The set supports deletion in so far as when you write to the set, if
your write is missing items that are currently present in the (local
version of the) set is assumed to be deleted.

### Options:

- `id_key`: Required. The key that identifies records in the set. Used for
  deduplication, deletion syncing, etc.

    This must point to a string property in each record.

- `prefer_deletions`: Optional (default to false). indicates whether updates or
  deletions win in the case of conflict. If true, then deletions always win,
  even if they are older. If false, then the last write wins.

- `default`: Optional default value. If provided, must an array of json objects.
  If the array is not empty, every item in it must have the `id_key`, the
  properties of those `id_key`s must be strings, and there may not be any two
  objects with the same `id_key`.

### Restrictions

- It's an error to use `record_set` in a schema's `dedupe_on`.
- `record_set` fields may not specify a merge strategy.
- `record_set` fields may not be part of a composite.

# Composite fields

If a field needs to indicate that it's conceptually part of a group that is
updated atomically, instead of a `merge` strategy, it can mark a
`composite_root`.

Composites are good for compound data types where any part of them may change,
but merging two records across these changes is fundamentally broken.

For example, credit card number and expiration date. If a user updates *just the
number* on device 1, then *just the expiration date* on device two, these two
updates are conceptually in conflict, but a field level three-way-merge (as we
do) will blindly combine them, producing a record that doesn't represent
anything the user ever saw.

Theyre also useful for cases where one or more fields store extra information
that pretains to the root field.

For example, you might want to merge using `take_max` for a last use timestamp,
and also some information about the use -- for example, which device it occurred
on. This can be done correctly by storing the last use timestamp as a `take_max`
`timestamp` field, and storing the device information on one or more fields
which reference the `timestamp` as their `composite_root`.

## Restrictions on composites

- Not all types can be part of a composite (many can't). Furthermore, some types
  may be part of a composite, but not as the root. See the field type docs for
  details.

- Members of composite fields may not specify a merge strategy.

- The composite root must use one of the following merge strategies, which
  effectively applies to the composite as a whole:

    - `take_newest`: On conflict of *any of the fields in the composite*,
      the most recently written value is used for all fields.

    - `prefer_remote`: On conflict of *any of the fields in the composite*,
      the remote value is used for all fields.

    - `take_min` and `take_max`: If the root of uses this as its merge strategy
      then on conflict with *any of the fields in the composite*, we compare the
      value of the remote composite root to the local composite root, and on
      conflict, the lesser/greater root value decides how all fields of the
      composite are resolved.

- If any member in a composite is part of a `dedupe_on`, all members must be listed
  in the dedupe_on.

- A field which is listed as a `composite_root` of another field may not, itself
  list a `composite_root`.

# Merge Strategies

It is important to note that these are only applied in the case of field-level
conflicts. That is, when the value is modified both locally and remotely.

- `take_newest`: Take the value for the field that was changed most recently.
  This is the default, and recommended for most data. That is, last write wins.

- `prefer_remote`: On conflict, assume we're wrong.
    - Note that this typically is not useful when specified manually, but is
      automatically used for cases where we 
    - TODO: This should probably take a parameter for the native schema version.

- `duplicate`: On conflict, duplicate the record. This is not recommended for
  most cases. Additionally no field may use this strategy in a record with a
  non-empty dedupe-on list.

- `take_min`: Numeric fields only. Take the minimum value between the two
  fields. Good for creation timestamps, and specified by default for timestamps
  with the `created_at` semantic.

- `take_max`: Numeric fields only. Take the larger value between the two fields.
  Good for creation timestamps, and specified by default for timestamps with the
  `updated_at` semantic.

- `take_sum`: Numeric fields only. Treat the value as if it's a monotonic sum.
  In the case of a conflict, if we have a common shared parent stored in the
  mirror, the the result value is computed as
    ```
    mirror_value += max(remote_value - mirror_value, 0) +
                    max(local_value - mirror_value, 0)
    ```
    In the case of a two way merge (when we do not have a shared parent), the
    larger value is used (this will generally be rare).

- `prefer_false`: Boolean fields only. On conflict, if either field is set to
  `false`, then the output is `false`.

    This is equivalent to a boolean "and" operation.

- `prefer_true`: Boolean fields only. On conflict, if either field is set to
    `true`, then the output is `true`.

    This is equivalent to a boolean "or" operation.


# `dedupe_on`

This indicates an identity relationship for your type.

In SQL terms, it effectively is a compound `UNIQUE` key, but perhaps without the
performance implications. If an incoming record appears which has identical
values to a local record for all keys listed in `dedupe_on`, then we treat it
as if the write applied to the same record (but perform a two way merge).

## Restrictions

- All strings listed in `dedupe_on` must point at ,
- No fields listed in `dedupe_on` may have a `type` or `merge` strategy that
  specifies that they cannot be part of `dedupe_on`
- Either all members of a composite, or no members of that composite may be
  listed in `dedupe_on`. (You may not have list only some of a composite's
  members)
- Types with non-empty `dedupe_on` lists may not use the `duplicate` merge
  strategy for any of their fields.


