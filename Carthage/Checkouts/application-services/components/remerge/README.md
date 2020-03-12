# Remerge: A syncable store for generic data types

Unfortunately, with the (indefinite) "pause" of Mentat, there's no obvious path
forward for new synced data types beyond 'the Sync team implements a new
component'. Presumably, at some point we decided this was both desirable, but
unworkable, hence designing Mentat.

Remerge is a storage/syncing solution that attempts to get us some of the
benefits of Mentat with the following major benefits (compared to Mentat)

- Works on top of Sync 1.5, including interfacing with existing collections,
- Doesn't change the sync data model substantially.
- Has storage which is straightforward to implement on top of SQLite.

For more information, please see the full RFC and documentation for remerge,
available [here](../../docs/design/remerge/rfc.md)

