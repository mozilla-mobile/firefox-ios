/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! Logins Schema v4
//! ================
//!
//! The schema we use is a evolution of the firefox-ios logins database format.
//! There are three tables:
//!
//! - `loginsL`: The local table.
//! - `loginsM`: The mirror table.
//! - `loginsSyncMeta`: The table used to to store various sync metadata.
//!
//! ## `loginsL`
//!
//! This stores local login information, also known as the "overlay".
//!
//! `loginsL` is essentially unchanged from firefox-ios, however note the
//! semantic change v4 makes to timestamp fields (which is explained in more
//! detail in the [COMMON_COLS] documentation).
//!
//! It is important to note that `loginsL` is not guaranteed to be present for
//! all records. Synced records may only exist in `loginsM` (although this is
//! not guaranteed). In either case, queries should read from both `loginsL` and
//! `loginsM`.
//!
//! ### `loginsL` Columns
//!
//! Contains all fields in [COMMON_COLS], as well as the following additional
//! columns:
//!
//! - `local_modified`: A millisecond local timestamp indicating when the record
//!   was changed locally, or NULL if the record has never been changed locally.
//!
//! - `is_deleted`: A boolean indicating whether or not this record is a
//!   tombstone.
//!
//! - `sync_status`: A `SyncStatus` enum value, one of
//!
//!     - `0` (`SyncStatus::Synced`): Indicating that the record has been synced
//!
//!     - `1` (`SyncStatus::Changed`): Indicating that the record should be
//!       has changed locally and is known to exist on the server.
//!
//!     - `2` (`SyncStatus::New`): Indicating that the record has never been
//!       synced, or we have been reset since the last time it synced.
//!
//! ## `loginsM`
//!
//! This stores server-side login information, also known as the "mirror".
//!
//! Like `loginsL`, `loginM` has not changed from firefox-ios, beyond the
//! change to store timestamps as milliseconds explained in [COMMON_COLS].
//!
//! Also like `loginsL`, `loginsM` is not guaranteed to have rows for all
//! records. It should not have rows for records which were not synced!
//!
//! It is important to note that `loginsL` is not guaranteed to be present for
//! all records. Synced records may only exist in `loginsM`! Queries should
//! test against both!
//!
//! ### `loginsM` Columns
//!
//! Contains all fields in [COMMON_COLS], as well as the following additional
//! columns:
//!
//! - `server_modified`: the most recent server-modification timestamp
//!   ([sync15::ServerTimestamp]) we've seen for this record. Stored as
//!   a millisecond value.
//!
//! - `is_overridden`: A boolean indicating whether or not the mirror contents
//!   are invalid, and that we should defer to the data stored in `loginsL`.
//!
//! ## `loginsSyncMeta`
//!
//! This is a simple key-value table based on the `moz_meta` table in places.
//! This table was added (by this rust crate) in version 4, and so is not
//! present in firefox-ios.
//!
//! Currently it is used to store two items:
//!
//! 1. The last sync timestamp is stored under [LAST_SYNC_META_KEY], a
//!    `sync15::ServerTimestamp` stored in integer milliseconds.
//!
//! 2. The persisted sync state machine information is stored under
//!    [GLOBAL_STATE_META_KEY]. This is a `sync15::GlobalState` stored as
//!    JSON.
//!

use crate::error::*;
use lazy_static::lazy_static;
use rusqlite::Connection;
use sql_support::ConnExt;

/// Note that firefox-ios is currently on version 3. Version 4 is this version,
/// which adds a metadata table and changes timestamps to be in milliseconds
pub const VERSION: i64 = 4;

/// Every column shared by both tables except for `id`
///
/// Note: `timeCreated`, `timeLastUsed`, and `timePasswordChanged` are in
/// milliseconds. This is in line with how the server and Desktop handle it, but
/// counter to how firefox-ios handles it (hence needing to fix them up
/// firefox-ios on schema upgrade from 3, the last firefox-ios password schema
/// version).
///
/// The reason for breaking from how firefox-ios does things is just because it
/// complicates the code to have multiple kinds of timestamps, for very little
/// benefit. It also makes it unclear what's stored on the server, leading to
/// further confusion.
///
/// However, note that the `local_modified` (of `loginsL`) and `server_modified`
/// (of `loginsM`) are stored as milliseconds as well both on firefox-ios and
/// here (and so they do not need to be updated with the `timeLastUsed`/
/// `timePasswordChanged`/`timeCreated` timestamps.
pub const COMMON_COLS: &str = "
    guid,
    username,
    password,
    hostname,
    httpRealm,
    formSubmitURL,
    usernameField,
    passwordField,
    timeCreated,
    timeLastUsed,
    timePasswordChanged,
    timesUsed
";

const COMMON_SQL: &str = "
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    hostname            TEXT NOT NULL,
    -- Exactly one of httpRealm or formSubmitURL should be set
    httpRealm           TEXT,
    formSubmitURL       TEXT,
    usernameField       TEXT,
    passwordField       TEXT,
    timesUsed           INTEGER NOT NULL DEFAULT 0,
    timeCreated         INTEGER NOT NULL,
    timeLastUsed        INTEGER,
    timePasswordChanged INTEGER NOT NULL,
    username            TEXT,
    password            TEXT NOT NULL,
    guid                TEXT NOT NULL UNIQUE
";

lazy_static! {
    static ref CREATE_LOCAL_TABLE_SQL: String = format!(
        "CREATE TABLE IF NOT EXISTS loginsL (
            {common_sql},
            -- Milliseconds, or NULL if never modified locally.
            local_modified INTEGER,

            is_deleted     TINYINT NOT NULL DEFAULT 0,
            sync_status    TINYINT NOT NULL DEFAULT 0
        )",
        common_sql = COMMON_SQL
    );
    static ref CREATE_MIRROR_TABLE_SQL: String = format!(
        "CREATE TABLE IF NOT EXISTS loginsM (
            {common_sql},
            -- Milliseconds (a sync15::ServerTimestamp multiplied by
            -- 1000 and truncated)
            server_modified INTEGER NOT NULL,
            is_overridden   TINYINT NOT NULL DEFAULT 0
        )",
        common_sql = COMMON_SQL
    );
    static ref SET_VERSION_SQL: String =
        format!("PRAGMA user_version = {version}", version = VERSION);
}

const CREATE_META_TABLE_SQL: &str = "
    CREATE TABLE IF NOT EXISTS loginsSyncMeta (
        key TEXT PRIMARY KEY,
        value NOT NULL
    )
";

const CREATE_OVERRIDE_HOSTNAME_INDEX_SQL: &str = "
    CREATE INDEX IF NOT EXISTS idx_loginsM_is_overridden_hostname
    ON loginsM (is_overridden, hostname)
";

const CREATE_DELETED_HOSTNAME_INDEX_SQL: &str = "
    CREATE INDEX IF NOT EXISTS idx_loginsL_is_deleted_hostname
    ON loginsL (is_deleted, hostname)
";

// As noted above, we use these when updating from schema v3 (firefox-ios's
// last schema) to convert from microsecond timestamps to milliseconds.
const UPDATE_LOCAL_TIMESTAMPS_TO_MILLIS_SQL: &str = "
    UPDATE loginsL
    SET timeCreated = timeCreated / 1000,
        timeLastUsed = timeLastUsed / 1000,
        timePasswordChanged = timePasswordChanged / 1000
";

const UPDATE_MIRROR_TIMESTAMPS_TO_MILLIS_SQL: &str = "
    UPDATE loginsM
    SET timeCreated = timeCreated / 1000,
        timeLastUsed = timeLastUsed / 1000,
        timePasswordChanged = timePasswordChanged / 1000
";

pub(crate) static LAST_SYNC_META_KEY: &str = "last_sync_time";
pub(crate) static GLOBAL_STATE_META_KEY: &str = "global_state_v2";
pub(crate) static GLOBAL_SYNCID_META_KEY: &str = "global_sync_id";
pub(crate) static COLLECTION_SYNCID_META_KEY: &str = "passwords_sync_id";

pub(crate) fn init(db: &Connection) -> Result<()> {
    let user_version = db.query_one::<i64>("PRAGMA user_version")?;
    if user_version == 0 {
        // This logic is largely taken from firefox-ios. AFAICT at some point
        // they went from having schema versions tracked using a table named
        // `tableList` to using `PRAGMA user_version`. This leads to the
        // following logic:
        //
        // - If `tableList` exists, we're hopelessly far in the past, drop any
        //   tables we have (to ensure we avoid name collisions/stale data) and
        //   recreate. (This is captured by the `upgrade` case where from == 0)
        //
        // - If `tableList` doesn't exist and `PRAGMA user_version` is 0, it's
        //   the first time through, just create the new tables.
        //
        // - Otherwise, it's a normal schema upgrade from an earlier
        //   `PRAGMA user_version`.
        let table_list_exists = db.query_one::<i64>(
            "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = 'tableList'",
        )? != 0;

        if table_list_exists {
            drop(db)?;
        }
        return create(db);
    }
    if user_version != VERSION {
        if user_version < VERSION {
            upgrade(db, user_version)?;
        } else {
            log::warn!(
                "Loaded future schema version {} (we only understand version {}). \
                 Optimistically ",
                user_version,
                VERSION
            )
        }
    }
    Ok(())
}

// https://github.com/mozilla-mobile/firefox-ios/blob/master/Storage/SQL/LoginsSchema.swift#L100
fn upgrade(db: &Connection, from: i64) -> Result<()> {
    log::debug!("Upgrading schema from {} to {}", from, VERSION);
    if from == VERSION {
        return Ok(());
    }
    assert_ne!(
        from, 0,
        "Upgrading from user_version = 0 should already be handled (in `init`)"
    );
    if from < 3 {
        // These indices were added in v3 (apparently)
        db.execute_all(&[
            CREATE_OVERRIDE_HOSTNAME_INDEX_SQL,
            CREATE_DELETED_HOSTNAME_INDEX_SQL,
        ])?;
    }
    if from < 4 {
        // This is the update from the firefox-ios schema to our schema.
        // The `loginsSyncMeta` table was added in v4, and we moved
        // from using microseconds to milliseconds for `timeCreated`,
        // `timeLastUsed`, and `timePasswordChanged`.
        db.execute_all(&[
            CREATE_META_TABLE_SQL,
            UPDATE_LOCAL_TIMESTAMPS_TO_MILLIS_SQL,
            UPDATE_MIRROR_TIMESTAMPS_TO_MILLIS_SQL,
            &*SET_VERSION_SQL,
        ])?;
    }
    Ok(())
}

pub(crate) fn create(db: &Connection) -> Result<()> {
    log::debug!("Creating schema");
    db.execute_all(&[
        &*CREATE_LOCAL_TABLE_SQL,
        &*CREATE_MIRROR_TABLE_SQL,
        CREATE_OVERRIDE_HOSTNAME_INDEX_SQL,
        CREATE_DELETED_HOSTNAME_INDEX_SQL,
        CREATE_META_TABLE_SQL,
        &*SET_VERSION_SQL,
    ])?;
    Ok(())
}

pub(crate) fn drop(db: &Connection) -> Result<()> {
    log::debug!("Dropping schema");
    db.execute_all(&[
        "DROP TABLE IF EXISTS loginsM",
        "DROP TABLE IF EXISTS loginsL",
        "DROP TABLE IF EXISTS loginsSyncMeta",
        "PRAGMA user_version = 0",
    ])?;
    Ok(())
}
