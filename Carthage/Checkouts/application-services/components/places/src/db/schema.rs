/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// XXXXXX - This has been cloned from logins/src/schema.rs, on Thom's
// wip-sync-sql-store branch.
// We should work out how to turn this into something that can use a shared
// db.rs.

use crate::api::places_api::ConnectionType;
use crate::bookmark_sync::store::LAST_SYNC_META_KEY;
use crate::db::PlacesDb;
use crate::error::*;
use crate::storage::bookmarks::{
    bookmark_sync::create_synced_bookmark_roots, create_bookmark_roots,
};
use crate::types::SyncStatus;
use rusqlite::NO_PARAMS;
use sql_support::ConnExt;

const VERSION: i64 = 10;

// Shared schema and temp tables for the read-write and Sync connections.
const CREATE_SHARED_SCHEMA_SQL: &str = include_str!("../../sql/create_shared_schema.sql");
const CREATE_SHARED_TEMP_TABLES_SQL: &str = include_str!("../../sql/create_shared_temp_tables.sql");

// Sync-specific temp tables and triggers.
const CREATE_SYNC_TEMP_TABLES_SQL: &str = include_str!("../../sql/create_sync_temp_tables.sql");
const CREATE_SYNC_TRIGGERS_SQL: &str = include_str!("../../sql/create_sync_triggers.sql");

// Triggers for the main read-write connection only.
const CREATE_MAIN_TRIGGERS_SQL: &str = include_str!("../../sql/create_main_triggers.sql");

lazy_static::lazy_static! {
    // Triggers for the read-write and Sync connections.
    static ref CREATE_SHARED_TRIGGERS_SQL: String = {
        format!(
            include_str!("../../sql/create_shared_triggers.sql"),
            increase_frecency_stats = update_origin_frecency_stats("+"),
            decrease_frecency_stats = update_origin_frecency_stats("-"),
        )
    };
}

// Keys in the moz_meta table.
pub(crate) static MOZ_META_KEY_ORIGIN_FRECENCY_COUNT: &str = "origin_frecency_count";
pub(crate) static MOZ_META_KEY_ORIGIN_FRECENCY_SUM: &str = "origin_frecency_sum";
pub(crate) static MOZ_META_KEY_ORIGIN_FRECENCY_SUM_OF_SQUARES: &str =
    "origin_frecency_sum_of_squares";

fn update_origin_frecency_stats(op: &str) -> String {
    format!(
        "
        INSERT OR REPLACE INTO moz_meta(key, value)
        SELECT
            '{frecency_count}',
            IFNULL((SELECT value FROM moz_meta WHERE key = '{frecency_count}'), 0)
                {op} CAST (frecency > 0 AS INT)
        FROM moz_origins WHERE prefix = OLD.prefix AND host = OLD.host
        UNION
        SELECT
            '{frecency_sum}',
            IFNULL((SELECT value FROM moz_meta WHERE key = '{frecency_sum}'), 0)
                {op} MAX(frecency, 0)
        FROM moz_origins WHERE prefix = OLD.prefix AND host = OLD.host
        UNION
        SELECT
            '{frecency_sum_of_squares}',
            IFNULL((SELECT value FROM moz_meta WHERE key = '{frecency_sum_of_squares}'), 0)
                {op} (MAX(frecency, 0) * MAX(frecency, 0))
        FROM moz_origins WHERE prefix = OLD.prefix AND host = OLD.host",
        op = op,
        frecency_count = MOZ_META_KEY_ORIGIN_FRECENCY_COUNT,
        frecency_sum = MOZ_META_KEY_ORIGIN_FRECENCY_SUM,
        frecency_sum_of_squares = MOZ_META_KEY_ORIGIN_FRECENCY_SUM_OF_SQUARES,
    )
}

fn get_current_schema_version(db: &PlacesDb) -> Result<i64> {
    Ok(db.query_one::<i64>("PRAGMA user_version")?)
}

pub fn init(db: &PlacesDb) -> Result<()> {
    let user_version = get_current_schema_version(db)?;
    if user_version == 0 {
        create(db)?;
    } else if user_version != VERSION {
        if user_version < VERSION {
            upgrade(db, user_version)?;
        } else {
            log::warn!(
                "Loaded future schema version {} (we only understand version {}). \
                 Optimistically ",
                user_version,
                VERSION
            );
            // Downgrade the schema version, so that anything added with our
            // schema is migrated forward when the newer library reads our
            // database.
            db.execute_batch(&format!("PRAGMA user_version = {};", VERSION))?;
        }
    }
    match db.conn_type() {
        // Read-only connections don't need temp tables or triggers, as they
        // can't write anything.
        ConnectionType::ReadOnly => {}

        // The main read-write connection needs shared and main-specific
        // temp tables and triggers (for example, for writing tombstones).
        ConnectionType::ReadWrite => {
            db.execute_batch(CREATE_SHARED_TEMP_TABLES_SQL)?;
            db.execute_batch(&CREATE_SHARED_TRIGGERS_SQL)?;
            db.execute_batch(CREATE_MAIN_TRIGGERS_SQL)?;
        }

        // The Sync connection needs shared and its own temp tables and
        // triggers, for merging. It also bypasses some of the main
        // triggers, so that we don't write tombstones for synced deletions.
        ConnectionType::Sync => {
            db.execute_batch(CREATE_SHARED_TEMP_TABLES_SQL)?;
            db.execute_batch(&CREATE_SHARED_TRIGGERS_SQL)?;
            db.execute_batch(CREATE_SYNC_TEMP_TABLES_SQL)?;
            db.execute_batch(CREATE_SYNC_TRIGGERS_SQL)?;
            create_synced_bookmark_roots(db)?;
        }
    }
    Ok(())
}

/// Helper for upgrade. Intended use:
///
/// ```rust,ignore
/// migration(db, 2, 3, &[stuff, to, migrate, version2, to, version3], || Ok(()))?;
/// migration(db, 3, 4, &[stuff, to, migrate, version3, to, version4], || Ok(()))?;
/// migration(db, 4, 5, &[stuff, to, migrate, version4, to, version5], || Ok(()))?;
/// assert_eq!(get_current_schema_version(), 5);
/// ```
///
/// The callback parameter is if any extra logic is needed for the migration
/// (for example, creating bookmark roots). In an ideal world, this would be an
/// Option, but sadly, that can't typecheck.
fn migration<F>(db: &PlacesDb, from: i64, to: i64, stmts: &[&str], extra_logic: F) -> Result<()>
where
    F: FnOnce() -> Result<()>,
{
    assert!(
        to <= VERSION,
        "Bug: Added migration without updating VERSION"
    );
    // In the future maybe we want to avoid calling this
    let cur_version = get_current_schema_version(db)?;
    if cur_version == from {
        log::debug!("Upgrading schema from {} to {}", cur_version, to);
        for stmt in stmts {
            db.execute_batch(stmt)?;
        }
        db.execute_batch(&format!("PRAGMA user_version = {};", to))?;
        extra_logic()?;
    } else {
        log::debug!(
            "Not executing places migration of v{} -> v{} on v{}",
            from,
            to,
            cur_version
        );
    }
    Ok(())
}

fn upgrade(db: &PlacesDb, from: i64) -> Result<()> {
    log::debug!("Upgrading schema from {} to {}", from, VERSION);
    if from == VERSION {
        return Ok(());
    }

    migration(db, 2, 3, &[CREATE_SHARED_SCHEMA_SQL], || Ok(()))?;
    migration(
        db,
        3,
        4,
        &[
            // Previous versions had an incomplete version of moz_bookmarks.
            "DROP TABLE moz_bookmarks",
            CREATE_SHARED_SCHEMA_SQL,
        ],
        || create_bookmark_roots(&db.conn()),
    )?;
    migration(db, 4, 5, &[CREATE_SHARED_SCHEMA_SQL], || Ok(()))?;
    migration(db, 5, 6, &[CREATE_SHARED_SCHEMA_SQL], || Ok(()))?; // new tags tables.
    migration(db, 6, 7, &[CREATE_SHARED_SCHEMA_SQL], || Ok(()))?; // bookmark syncing.
    migration(
        db,
        7,
        8,
        &[
            // Changing `moz_bookmarks_synced_structure` to store multiple
            // parents, so we need to re-download all synced bookmarks.
            &format!("DELETE FROM moz_meta WHERE key = '{}'", LAST_SYNC_META_KEY),
            "DROP TABLE moz_bookmarks_synced",
            "DROP TABLE moz_bookmarks_synced_structure",
            CREATE_SHARED_SCHEMA_SQL,
        ],
        || Ok(()),
    )?;
    migration(
        db,
        8,
        9,
        &[
            // Bump change counter of New() items due to bookmarks `reset`
            // setting the counter to 0 instead of 1 (#1145)
            &format!(
                "UPDATE moz_bookmarks
                 SET syncChangeCounter = syncChangeCounter + 1
                 WHERE syncStatus = {}",
                SyncStatus::New as u8
            ),
        ],
        || Ok(()),
    )?;
    migration(
        db,
        9,
        10,
        &[
            // Add an index for synced bookmark URLs.
            "CREATE INDEX IF NOT EXISTS moz_bookmarks_synced_urls
             ON moz_bookmarks_synced(placeId)",
        ],
        || Ok(()),
    )?;
    // Add more migrations here...

    if get_current_schema_version(db)? == VERSION {
        return Ok(());
    }
    Err(ErrorKind::DatabaseUpgradeError.into())
}

pub fn create(db: &PlacesDb) -> Result<()> {
    log::debug!("Creating schema");
    db.execute_batch(CREATE_SHARED_SCHEMA_SQL)?;
    create_bookmark_roots(&db.conn())?;
    db.execute(
        &format!("PRAGMA user_version = {version}", version = VERSION),
        NO_PARAMS,
    )?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::PlacesDb;
    use sync_guid::Guid as SyncGuid;
    use url::Url;

    #[test]
    fn test_create_schema_twice() {
        let conn = PlacesDb::open_in_memory(ConnectionType::ReadWrite).expect("no memory db");
        conn.execute_batch(CREATE_SHARED_SCHEMA_SQL)
            .expect("should allow running twice");
    }

    fn has_tombstone(conn: &PlacesDb, guid: &SyncGuid) -> bool {
        let count: Result<Option<u32>> = conn.try_query_row(
            "SELECT COUNT(*) from moz_places_tombstones
                     WHERE guid = :guid",
            &[(":guid", guid)],
            |row| Ok(row.get::<_, u32>(0)?),
            true,
        );
        count.unwrap().unwrap() == 1
    }

    #[test]
    fn test_places_no_tombstone() {
        let conn = PlacesDb::open_in_memory(ConnectionType::ReadWrite).expect("no memory db");
        let guid = SyncGuid::random();

        conn.execute_named_cached(
            "INSERT INTO moz_places (guid, url, url_hash) VALUES (:guid, :url, hash(:url))",
            &[
                (":guid", &guid),
                (
                    ":url",
                    &Url::parse("http://example.com")
                        .expect("valid url")
                        .into_string(),
                ),
            ],
        )
        .expect("should work");

        let place_id = conn.last_insert_rowid();
        conn.execute_named_cached(
            "DELETE FROM moz_places WHERE id = :id",
            &[(":id", &place_id)],
        )
        .expect("should work");

        // should not have a tombstone.
        assert!(!has_tombstone(&conn, &guid));
    }

    #[test]
    fn test_places_tombstone_removal() {
        let conn = PlacesDb::open_in_memory(ConnectionType::ReadWrite).expect("no memory db");
        let guid = SyncGuid::random();

        conn.execute_named_cached(
            "INSERT INTO moz_places_tombstones VALUES (:guid)",
            &[(":guid", &guid)],
        )
        .expect("should work");

        // insert into moz_places - the tombstone should be removed.
        conn.execute_named_cached(
            "INSERT INTO moz_places (guid, url, url_hash, sync_status)
             VALUES (:guid, :url, hash(:url), :sync_status)",
            &[
                (":guid", &guid),
                (
                    ":url",
                    &Url::parse("http://example.com")
                        .expect("valid url")
                        .into_string(),
                ),
                (":sync_status", &SyncStatus::Normal),
            ],
        )
        .expect("should work");
        assert!(!has_tombstone(&conn, &guid));
    }

    #[test]
    fn test_bookmark_check_constraints() {
        let conn = PlacesDb::open_in_memory(ConnectionType::ReadWrite).expect("no memory db");

        // type==BOOKMARK but null fk
        let e = conn
            .execute_cached(
                "INSERT INTO moz_bookmarks
                    (fk, type, parent, position, dateAdded, lastModified, guid)
                 VALUES
                    (NULL, 1, 0, 0, 1, 1, 'fake_guid___')",
                NO_PARAMS,
            )
            .expect_err("should fail");
        assert_eq!(e.to_string(), "CHECK constraint failed: moz_bookmarks");

        // type!=BOOKMARK and non-null fk
        let e = conn
            .execute_cached(
                "INSERT INTO moz_bookmarks
                    (fk, type, parent, position, dateAdded, lastModified, guid)
                 VALUES
                    (1, 2, 0, 0, 1, 1, 'fake_guid___')",
                NO_PARAMS,
            )
            .expect_err("should fail");
        assert_eq!(e.to_string(), "CHECK constraint failed: moz_bookmarks");

        // null parent for item other than the root
        let e = conn
            .execute_cached(
                "INSERT INTO moz_bookmarks
                    (fk, type, parent, position, dateAdded, lastModified, guid)
                 VALUES
                    (NULL, 2, NULL, 0, 1, 1, 'fake_guid___')",
                NO_PARAMS,
            )
            .expect_err("should fail");
        assert_eq!(e.to_string(), "CHECK constraint failed: moz_bookmarks");

        // Invalid length guid
        let e = conn
            .execute_cached(
                "INSERT INTO moz_bookmarks
                    (fk, type, parent, position, dateAdded, lastModified, guid)
                 VALUES
                    (NULL, 2, 0, 0, 1, 1, 'fake_guid')",
                NO_PARAMS,
            )
            .expect_err("should fail");
        assert_eq!(e.to_string(), "CHECK constraint failed: moz_bookmarks");
    }

    fn select_simple_int(conn: &PlacesDb, stmt: &str) -> u32 {
        let count: Result<Option<u32>> =
            conn.try_query_row(stmt, &[], |row| Ok(row.get::<_, u32>(0)?), false);
        count.unwrap().unwrap()
    }

    fn get_foreign_count(conn: &PlacesDb, guid: &SyncGuid) -> u32 {
        let count: Result<Option<u32>> = conn.try_query_row(
            "SELECT foreign_count from moz_places
                     WHERE guid = :guid",
            &[(":guid", guid)],
            |row| Ok(row.get::<_, u32>(0)?),
            true,
        );
        count.unwrap().unwrap()
    }

    #[test]
    fn test_bookmark_foreign_count_triggers() {
        // create the place.
        let conn = PlacesDb::open_in_memory(ConnectionType::ReadWrite).expect("no memory db");
        let guid1 = SyncGuid::random();
        let url1 = Url::parse("http://example.com")
            .expect("valid url")
            .into_string();
        let guid2 = SyncGuid::random();
        let url2 = Url::parse("http://example2.com")
            .expect("valid url")
            .into_string();

        conn.execute_named_cached(
            "INSERT INTO moz_places (guid, url, url_hash) VALUES (:guid, :url, hash(:url))",
            &[(":guid", &guid1), (":url", &url1)],
        )
        .expect("should work");
        let place_id1 = conn.last_insert_rowid();

        conn.execute_named_cached(
            "INSERT INTO moz_places (guid, url, url_hash) VALUES (:guid, :url, hash(:url))",
            &[(":guid", &guid2), (":url", &url2)],
        )
        .expect("should work");
        let place_id2 = conn.last_insert_rowid();

        assert_eq!(get_foreign_count(&conn, &guid1), 0);
        assert_eq!(get_foreign_count(&conn, &guid2), 0);

        // create a bookmark pointing at it.
        conn.execute_named_cached(
            "INSERT INTO moz_bookmarks
                (fk, type, parent, position, dateAdded, lastModified, guid)
            VALUES
                (:place_id, 1, 1, 0, 1, 1, 'fake_guid___')",
            &[(":place_id", &place_id1)],
        )
        .expect("should work");
        assert_eq!(get_foreign_count(&conn, &guid1), 1);
        assert_eq!(get_foreign_count(&conn, &guid2), 0);

        // change the bookmark to point at a different place.
        conn.execute_named_cached(
            "UPDATE moz_bookmarks SET fk = :new_place WHERE guid = 'fake_guid___';",
            &[(":new_place", &place_id2)],
        )
        .expect("should work");
        assert_eq!(get_foreign_count(&conn, &guid1), 0);
        assert_eq!(get_foreign_count(&conn, &guid2), 1);

        conn.execute(
            "DELETE FROM moz_bookmarks WHERE guid = 'fake_guid___';",
            NO_PARAMS,
        )
        .expect("should work");
        assert_eq!(get_foreign_count(&conn, &guid1), 0);
        assert_eq!(get_foreign_count(&conn, &guid2), 0);
    }

    #[test]
    fn test_bookmark_synced_foreign_count_triggers() {
        // create the place.
        let conn = PlacesDb::open_in_memory(ConnectionType::ReadWrite).expect("no memory db");

        let url = Url::parse("http://example.com")
            .expect("valid url")
            .into_string();

        conn.execute_named_cached(
            "INSERT INTO moz_places (guid, url, url_hash) VALUES ('fake_guid___', :url, hash(:url))",
            &[(":url", &url)],
        )
        .expect("should work");
        let place_id = conn.last_insert_rowid();

        assert_eq!(get_foreign_count(&conn, &"fake_guid___".into()), 0);

        // create a bookmark pointing at it.
        conn.execute_named_cached(
            "INSERT INTO moz_bookmarks_synced
                (placeId, guid)
            VALUES
                (:place_id, 'fake_guid___')",
            &[(":place_id", &place_id)],
        )
        .expect("should work");
        assert_eq!(get_foreign_count(&conn, &"fake_guid___".into()), 1);

        // delete it.
        conn.execute_named_cached(
            "DELETE FROM moz_bookmarks_synced WHERE guid = 'fake_guid___';",
            &[],
        )
        .expect("should work");
        assert_eq!(get_foreign_count(&conn, &"fake_guid___".into()), 0);
    }

    #[test]
    fn test_bookmark_delete_restrict() {
        let conn = PlacesDb::open_in_memory(ConnectionType::ReadWrite).expect("no memory db");
        conn.execute_all(&[
            "INSERT INTO moz_places
                (guid, url, url_hash)
             VALUES
                ('place_guid__', 'http://example.com/', hash('http://example.com/'))",
            "INSERT INTO moz_bookmarks
                (type, parent, position, dateAdded, lastModified, guid, fk)
            VALUES
                (1, 1, 0, 1, 1, 'fake_guid___', last_insert_rowid())",
        ])
        .expect("should be able to do the inserts");

        // Should be impossible to delete the place.
        conn.execute(
            "DELETE FROM moz_places WHERE guid = 'place_guid__';",
            NO_PARAMS,
        )
        .expect_err("should fail");

        // delete the bookmark.
        conn.execute(
            "DELETE FROM moz_bookmarks WHERE guid = 'fake_guid___';",
            NO_PARAMS,
        )
        .expect("should be able to delete the bookmark");

        // now we should be able to delete the place.
        conn.execute(
            "DELETE FROM moz_places WHERE guid = 'place_guid__';",
            NO_PARAMS,
        )
        .expect("should now be able to delete the place");
    }

    #[test]
    fn test_bookmark_auto_deletes() {
        let conn = PlacesDb::open_in_memory(ConnectionType::ReadWrite).expect("no memory db");

        conn.execute_all(&[
            // A folder to hold a bookmark.
            "INSERT INTO moz_bookmarks
                (type, parent, position, dateAdded, lastModified, guid)
            VALUES
                (3, 1, 0, 1, 1, 'folder_guid_')",
            // A place for the bookmark.
            "INSERT INTO moz_places
                (guid, url, url_hash)
            VALUES ('place_guid__', 'http://example.com/', hash('http://example.com/'))",
            // The bookmark.
            "INSERT INTO moz_bookmarks
                (fk, type, parent, position, dateAdded, lastModified, guid)
            VALUES
                --fk,                  type
                (last_insert_rowid(), 1,
                -- parent
                 (SELECT id FROM moz_bookmarks WHERE guid = 'folder_guid_'),
                -- positon, dateAdded, lastModified, guid
                   0,       1,         1,           'bookmarkguid')",
        ])
        .expect("inserts should work");

        // Delete the folder - the bookmark should cascade delete.
        conn.execute(
            "DELETE FROM moz_bookmarks WHERE guid = 'folder_guid_';",
            NO_PARAMS,
        )
        .expect("should work");

        // folder should be gone.
        assert_eq!(
            select_simple_int(
                &conn,
                "SELECT count(*) FROM moz_bookmarks WHERE guid = 'folder_guid_'"
            ),
            0
        );
        // bookmark should be gone.
        assert_eq!(
            select_simple_int(
                &conn,
                "SELECT count(*) FROM moz_bookmarks WHERE guid = 'bookmarkguid';"
            ),
            0
        );

        // Place should remain.
        assert_eq!(
            select_simple_int(
                &conn,
                "SELECT COUNT(*) from moz_places WHERE guid = 'place_guid__';"
            ),
            1
        );
    }

    #[test]
    fn test_bookmark_tombstone_auto_created() {
        let conn = PlacesDb::open_in_memory(ConnectionType::ReadWrite).expect("no memory db");
        conn.execute(
            &format!(
                "INSERT INTO moz_bookmarks
                        (syncStatus, type, parent, position, dateAdded, lastModified, guid)
                     VALUES
                        ({}, 3, 1, 0, 1, 1, 'bookmarkguid')",
                SyncStatus::Normal as u8
            ),
            NO_PARAMS,
        )
        .expect("should insert regular bookmark folder");
        conn.execute(
            "DELETE FROM moz_bookmarks WHERE guid = 'bookmarkguid'",
            NO_PARAMS,
        )
        .expect("should delete");
        // should have a tombstone.
        assert_eq!(
            select_simple_int(&conn, "SELECT COUNT(*) from moz_bookmarks_deleted"),
            1
        );
        conn.execute("DELETE from moz_bookmarks_deleted", NO_PARAMS)
            .expect("should delete");
        conn.execute(
            &format!(
                "INSERT INTO moz_bookmarks
                        (syncStatus, type, parent, position, dateAdded, lastModified, guid)
                     VALUES
                        ({}, 3, 1, 0, 1, 1, 'bookmarkguid')",
                SyncStatus::New as u8
            ),
            NO_PARAMS,
        )
        .expect("should insert regular bookmark folder");
        conn.execute(
            "DELETE FROM moz_bookmarks WHERE guid = 'bookmarkguid'",
            NO_PARAMS,
        )
        .expect("should delete");
        // should not have a tombstone as syncStatus is new.
        assert_eq!(
            select_simple_int(&conn, "SELECT COUNT(*) from moz_bookmarks_deleted"),
            0
        );
    }

    #[test]
    fn test_bookmark_tombstone_auto_deletes() {
        let conn = PlacesDb::open_in_memory(ConnectionType::ReadWrite).expect("no memory db");
        conn.execute(
            "INSERT into moz_bookmarks_deleted VALUES ('bookmarkguid', 1)",
            NO_PARAMS,
        )
        .expect("should insert tombstone");
        assert_eq!(
            select_simple_int(&conn, "SELECT COUNT(*) from moz_bookmarks_deleted"),
            1
        );
        // create a bookmark with the same guid.
        conn.execute(
            "INSERT INTO moz_bookmarks
                        (type, parent, position, dateAdded, lastModified, guid)
                     VALUES
                        (3, 1, 0, 1, 1, 'bookmarkguid')",
            NO_PARAMS,
        )
        .expect("should insert regular bookmark folder");
        // tombstone should have vanished.
        assert_eq!(
            select_simple_int(&conn, "SELECT COUNT(*) from moz_bookmarks_deleted"),
            0
        );
    }

    #[test]
    fn test_bookmark_tombstone_auto_deletes_on_update() {
        let conn = PlacesDb::open_in_memory(ConnectionType::ReadWrite).expect("no memory db");

        // check updates do the right thing.
        conn.execute(
            "INSERT into moz_bookmarks_deleted VALUES ('bookmarkguid', 1)",
            NO_PARAMS,
        )
        .expect("should insert tombstone");

        // create a bookmark with a different guid.
        conn.execute(
            "INSERT INTO moz_bookmarks
                        (type, parent, position, dateAdded, lastModified, guid)
                     VALUES
                        (3, 1, 0, 1, 1, 'fake_guid___')",
            NO_PARAMS,
        )
        .expect("should insert regular bookmark folder");
        // tombstone should remain.
        assert_eq!(
            select_simple_int(&conn, "SELECT COUNT(*) from moz_bookmarks_deleted"),
            1
        );
        // update guid - should fail as we have a trigger with RAISEs.
        conn.execute(
            "UPDATE moz_bookmarks SET guid = 'bookmarkguid'
             WHERE guid = 'fake_guid___'",
            NO_PARAMS,
        )
        .expect_err("changing the guid should fail");
    }
}
