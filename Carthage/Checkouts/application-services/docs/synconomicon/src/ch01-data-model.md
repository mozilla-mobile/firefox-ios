# Sync data model

All synced data types fit into one of three broad categories: trees, logs, and documents.

## Trees

Bookmarks are an example of a tree. Trees are hierarchical, and the most complex type to sync. Records in tree collections are interdependent, where parents contain pointers to their children, and children back to their parents.

Tree-structured data presents a problem for syncing, because some changes may span multiple records. These changes must be uploaded in lockstep, and applied in order. Missing or incomplete records lead to problems like orphans and parent-child disagreements. Clients must also be prepared to handle and fix inconsistent structure on the server.

## Logs

History is an example of a log. Logs are append-only, independent, and can be synced in any order. Since all entries are distinct, there are no conflicts: two visits to the same page on two different devices are still two distinct visits. These records are independent, and can be synced in any order.

Log data is the easiest to sync, but the problem is _volume_. We currently limit history to the last 20 visits per page, cap initial syncs to 5,000 pages in the last 30 days, and expire records that aren't updated on the server after 60 days. These limitations are for efficiency as much as for historical reasons. Clients don't need to process thousands of entries on each sync, and the server avoids bloated indexes for large collections. Unfortunately, this is also a form of data loss, as the server never has the complete history.

## Documents

Logins, addresses, and credit cards are examples of semistructured document data. Like logs, documents are independent, and can be synced in any order relative to each other. However, they _can_ conflict if two clients change the same record.

Engines that implement three-way merging support per-field conflict resolution, since they store the value that was last uploaded to the server. However, engines that only support two-way merging resolve conflicts at the record level, based on which side is newer.

Documents _can_ refer to other records. For example, credit cards have an "address hint" that points to a potential address record for the card. However, these identifiers aren't stable, and can't be enforced by the server or other clients. Each client must expect and handle stale and nonexistent references.

There's a [proposal to support generic syncing](https://github.com/mozilla/application-services/pull/658) for document types. We expect most new data types to fall into this category.

## Change tracking

Each client must track changes to synced data, so that it knows what to upload during the next sync. How this is done depends on the client, the data type, and the underlying store.

## Server record format

On the server, each piece of synced data is stored as a Basic Storage Object, or BSO. A BSO is a JSON envelope that contains an encrypted blob, which is itself a JSON string when decrypted. BSOs are grouped together in buckets called collections, where each BSO belonging to the same collection has the same structure.

BSOs are typically referenced as `collection/id`. For example, `meta/global` means "the BSO `global` in the `meta` collection." Most BSOs have a random, globally unique identifier, like `bookmarks/fvcXYVP3pY2w`. Others, like `meta/global` and `crypto/keys`, have well-known names.

BSOs are encrypted on the client side before upload, and decrypted during download. This means the server can't see the contents of any Sync records, except for their collection names, IDs, and last modified timestamps.
