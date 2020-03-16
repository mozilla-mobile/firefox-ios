/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::api::places_api::PlacesApi;
use crate::bookmark_sync::{
    store::{BookmarksStore, Merger},
    SyncedBookmarkKind,
};
use crate::db::db::PlacesDb;
use crate::error::*;
use crate::import::common::{attached_database, ExecuteOnDrop};
use crate::storage::bookmarks::{bookmark_sync::create_synced_bookmark_roots, PublicNode};
use crate::types::{BookmarkType, SyncStatus};
use rusqlite::NO_PARAMS;
use serde_derive::*;
use sql_support::ConnExt;
use std::time::Instant;
use url::Url;

// From https://searchfox.org/mozilla-central/rev/597a69c70a5cce6f42f159eb54ad1ef6745f5432/mobile/android/base/java/org/mozilla/gecko/db/BrowserDatabaseHelper.java#73.
const FENNEC_DB_VERSION: i64 = 39;

#[derive(Serialize, Deserialize, PartialEq, Debug, Clone, Default)]
pub struct BookmarksMigrationResult {
    pub num_total: u32,
    pub num_succeeded: u32,
    pub num_failed: u32,
    pub total_duration: u128,
}

fn select_count(conn: &PlacesDb, stmt: &str) -> u32 {
    let count: Result<Option<u32>> =
        conn.try_query_row(stmt, &[], |row| Ok(row.get::<_, u32>(0)?), false);
    count.unwrap().unwrap()
}

pub fn import(
    places_api: &PlacesApi,
    path: impl AsRef<std::path::Path>,
) -> Result<BookmarksMigrationResult> {
    let url = crate::util::ensure_url_path(path)?;
    do_import(places_api, url)
}

pub fn import_pinned_sites(
    places_api: &PlacesApi,
    path: impl AsRef<std::path::Path>,
) -> Result<Vec<PublicNode>> {
    let url = crate::util::ensure_url_path(path)?;
    do_pinned_sites_import(places_api, url)
}

fn do_import(places_api: &PlacesApi, fennec_db_file_url: Url) -> Result<BookmarksMigrationResult> {
    let conn = places_api.open_sync_connection()?;

    let scope = conn.begin_interrupt_scope();

    sql_fns::define_functions(&conn)?;

    // Not sure why, but apparently beginning a transaction sometimes
    // fails if we open the DB as read-only. Hopefully we don't
    // unintentionally write to it anywhere...
    // fennec_db_file_url.query_pairs_mut().append_pair("mode", "ro");

    let import_start = Instant::now();
    log::trace!("Attaching database {}", fennec_db_file_url);
    let auto_detach = attached_database(&conn, &fennec_db_file_url, "fennec")?;

    let db_version = conn.db.query_one::<i64>("PRAGMA fennec.user_version")?;
    if db_version != FENNEC_DB_VERSION {
        return Err(ErrorKind::UnsupportedDatabaseVersion(db_version).into());
    }

    let tx = conn.begin_transaction()?;

    let clear_mirror_on_drop = ExecuteOnDrop::new(&conn, WIPE_MIRROR.to_string());

    log::debug!("Counting Fennec bookmarks");
    let num_total = select_count(&conn, &COUNT_FENNEC_BOOKMARKS);

    // Clear the mirror now, since we're about to fill it with data from the fennec
    // connection.
    log::debug!("Clearing mirror to prepare for import");
    conn.execute_batch(&WIPE_MIRROR)?;
    scope.err_if_interrupted()?;

    log::debug!("Populating mirror with the bookmarks roots");
    create_synced_bookmark_roots(&conn)?;
    scope.err_if_interrupted()?;

    log::debug!("Creating staging table");
    conn.execute_batch(&CREATE_STAGING_TABLE)?;

    log::debug!("Importing from Fennec to staging table");
    conn.execute_batch(&POPULATE_STAGING)?;
    scope.err_if_interrupted()?;

    log::debug!("Populating missing entries in moz_places");
    conn.execute_batch(&FILL_MOZ_PLACES)?;
    scope.err_if_interrupted()?;

    log::debug!("Populating mirror");
    conn.execute_batch(&POPULATE_MIRROR)?;
    scope.err_if_interrupted()?;

    // Ideally we could just do this right after `CREATE_AND_POPULATE_STAGING`,
    // but we have constraints on the mirror structure that prevent this (and
    // there's probably nothing bad that can happen in this case anyway). We
    // could turn use `PRAGMA defer_foreign_keys = true`, but since we commit
    // everything in one go, that seems harder to debug.
    log::debug!("Populating mirror structure");
    conn.execute_batch(&POPULATE_MIRROR_STRUCTURE)?;
    scope.err_if_interrupted()?;

    let store = BookmarksStore::new(&conn, &scope);
    let mut merger = Merger::new(&store, Default::default());
    // We're already in a transaction.
    merger.set_external_transaction(true);
    log::debug!("Merging with local records");
    merger.merge()?;
    scope.err_if_interrupted()?;

    // Update last modification time, sync status, etc
    log::debug!("Fixing up bookmarks");
    conn.execute_batch(&FIXUP_MOZ_BOOKMARKS)?;
    scope.err_if_interrupted()?;
    log::debug!("Cleaning up mirror...");
    clear_mirror_on_drop.execute_now()?;
    log::debug!("Committing...");
    tx.commit()?;

    // Note: update_frecencies manages its own transaction, which is fine,
    // since nothing that bad will happen if it is aborted.
    log::debug!("Updating frecencies");
    store.update_frecencies()?;

    log::debug!("Counting Fenix bookmarks");
    let num_succeeded = select_count(&conn, &COUNT_FENIX_BOOKMARKS);
    // saturating_sub because num_succeeded could be > num_total due to
    // us auto-creating missing roots...
    let num_failed = num_total.saturating_sub(num_succeeded);

    auto_detach.execute_now()?;

    let metrics = BookmarksMigrationResult {
        num_total,
        num_succeeded,
        num_failed,
        total_duration: import_start.elapsed().as_millis(),
    };
    log::info!("Successfully imported bookmarks: {:?}", metrics);

    Ok(metrics)
}

fn do_pinned_sites_import(
    places_api: &PlacesApi,
    fennec_db_file_url: Url,
) -> Result<Vec<PublicNode>> {
    let conn = places_api.open_sync_connection()?;
    let scope = conn.begin_interrupt_scope();

    sql_fns::define_functions(&conn)?;

    log::trace!("Attaching database {}", fennec_db_file_url);
    let auto_detach = attached_database(&conn, &fennec_db_file_url, "fennec")?;

    let db_version = conn.db.query_one::<i64>("PRAGMA fennec.user_version")?;
    if db_version != FENNEC_DB_VERSION {
        return Err(ErrorKind::UnsupportedDatabaseVersion(db_version).into());
    }

    log::debug!("Fetching pinned websites");
    // Grab the pinned websites (they are stored as bookmarks).
    let mut stmt = conn.prepare(&FETCH_PINNED)?;
    let pinned_rows = stmt.query_map(NO_PARAMS, public_node_from_fennec_pinned)?;
    scope.err_if_interrupted()?;
    let mut pinned = Vec::new();
    for row in pinned_rows {
        pinned.push(row?);
    }

    log::info!("Successfully fetched pinned websites");
    auto_detach.execute_now()?;

    Ok(pinned)
}

#[derive(Clone, Copy, PartialEq, PartialOrd, Hash, Debug, Eq, Ord)]
#[repr(u8)]
pub enum FennecBookmarkType {
    // https://searchfox.org/mozilla-central/rev/ec806131cb7bcd1c26c254d25cd5ab8a61b2aeb6/mobile/android/base/java/org/mozilla/gecko/db/BrowserContract.java#291-295
    Folder = 0,
    Bookmark = 1,
    Separator = 2,
    // Not supported
    // Livemark = 3,
    // Query = 4,
}

lazy_static::lazy_static! {
    // Insert any missing entries into moz_places that we'll need for this.
    // No need to validate URLs here because we already did when filling the
    // staging table.
    static ref FILL_MOZ_PLACES: String = format!(
        "INSERT OR IGNORE INTO main.moz_places(guid, url, url_hash, frecency)
         SELECT IFNULL((SELECT p.guid FROM main.moz_places p
                        WHERE p.url_hash = hash(b.bmkUri) AND p.url = b.bmkUri),
                       generate_guid()),
                b.bmkUri,
                hash(b.bmkUri),
                -1
         FROM temp.fennecBookmarksStaging b
         WHERE b.bmkUri IS NOT NULL
           AND b.type = {bookmark_type}",
        bookmark_type = FennecBookmarkType::Bookmark as u8,
    );

    static ref POPULATE_MIRROR: String = format!(
        "REPLACE INTO main.moz_bookmarks_synced(
            guid,
            parentGuid,
            serverModified,
            needsMerge,
            validity,
            isDeleted,
            kind,
            dateAdded,
            title,
            placeId,
            keyword
        )
        SELECT
            b.guid,
            b.parent_guid,
            b.modified,
            1, -- needsMerge
            1, -- VALIDITY_VALID
            0, -- isDeleted
            CASE b.type
                WHEN {fennec_bookmark_type} THEN {bookmark_kind}
                WHEN {fennec_folder_type} THEN {folder_kind}
                WHEN {fennec_separator_type} THEN {separator_kind}
                -- We filter out anything else when inserting into the stage table
            END,
            b.date_added,
            b.title,
            -- placeId
            CASE WHEN b.bmkUri IS NULL
            THEN NULL
            ELSE (SELECT id FROM main.moz_places p
                  WHERE p.url_hash = hash(b.bmkUri) AND p.url = b.bmkUri)
            END,
            b.keyword
        FROM fennecBookmarksStaging b",
        bookmark_kind = SyncedBookmarkKind::Bookmark as u8,
        folder_kind = SyncedBookmarkKind::Folder as u8,
        separator_kind = SyncedBookmarkKind::Separator as u8,

        fennec_bookmark_type = FennecBookmarkType::Bookmark as u8,
        fennec_folder_type = FennecBookmarkType::Folder as u8,
        fennec_separator_type = FennecBookmarkType::Separator as u8,
    );
}

const WIPE_MIRROR: &str = "DELETE FROM main.moz_bookmarks_synced;
 DELETE FROM main.moz_bookmarks_synced_structure;";

const POPULATE_MIRROR_STRUCTURE: &str = "
REPLACE INTO main.moz_bookmarks_synced_structure(guid, parentGuid, position)
    SELECT stage.guid, stage.parent_guid, stage.pos FROM fennecBookmarksStaging stage;
";

lazy_static::lazy_static! {
    // Notes on 'date_added' and 'modified' below:
    // * In all cases, we want to maintain the invariants that:
    //   - timestamps should be >= Timestamp::EARLIEST and <= now.
    //   - in all cases, date_added must be <= modified.
    //   Which is tricky enough to express by itself, but further:
    // * If a Fennec item has either 'keyword' or 'tags', we want to ensure
    //   the remote version of the bookmark is considered later than the local
    //   copy - so in that case, we want the 'modified' value to be equal to the
    //   (sanitized and checked for not being > than) created value.

    // Note that strictly speaking, the 'keyword' check is an optimization as,
    // for accidental implementation reasons, we would upload a new version with
    // the keyword in place. But it's critical for 'tags' because we'd overwrite
    // the server record with the tag removed.
    // See the tests in fennec_bookmarks.rs for more detail here.
    static ref POPULATE_STAGING: String = format!(
        "INSERT OR IGNORE INTO temp.fennecBookmarksStaging(
            guid,
            type,
            parent_guid,
            pos,
            title,
            bmkUri,
            keyword,
            tags,
            date_added,
            modified,
            isLocal
        )
        SELECT
            normalize_root_guid(sanitize_utf8(b.guid)),
            b.type,
            IFNULL((SELECT normalize_root_guid(sanitize_utf8(p.guid)) FROM fennec.bookmarks p WHERE p._id = b.parent), 'unfiled_____'),
            b.position,
            sanitize_utf8(b.title),
            CASE
                WHEN b.url IS NOT NULL
                    THEN validate_url(b.url)
                ELSE NULL
            END as uri,
            sanitize_utf8(b.keyword),
            sanitize_utf8(b.tags),
            -- See above for notes about 'date_added' and 'modified'
            CASE
                WHEN b.tags IS NOT NULL OR
                     b.tags <> '' OR
                     b.keyword IS NOT NULL OR
                     b.keyword <> '' THEN
                        min(sanitize_timestamp(b.created), sanitize_timestamp(b.modified))
                ELSE sanitize_timestamp(b.created)
            END,
            CASE
                WHEN b.tags IS NOT NULL OR
                     b.tags <> '' OR
                     b.keyword IS NOT NULL OR
                     b.keyword <> '' THEN
                        min(sanitize_timestamp(b.created), sanitize_timestamp(b.modified))
                ELSE max(sanitize_timestamp(b.created), sanitize_timestamp(b.modified))
            END,
            1
        FROM fennec.bookmarks b
        WHERE NOT b.deleted
              AND (type != {fennec_bookmark_type} OR uri IS NOT NULL)
        ;
        ",
        fennec_bookmark_type = FennecBookmarkType::Bookmark as u8
    );

    static ref FETCH_PINNED: String = format!("
        SELECT
            b.guid,
            MAX(0, b.position) as position,
            b.title,
            b.url,
            sanitize_timestamp(b.created) as created,
            sanitize_timestamp(b.modified) as modified
        FROM fennec.bookmarks b
        WHERE
            b.type == {fennec_bookmark_type} AND
            b.parent = {fennec_pinned_parent_id} AND
            NOT b.deleted
        ;
    ",
        fennec_bookmark_type = FennecBookmarkType::Bookmark as u8,
        fennec_pinned_parent_id = -3,
    );

    static ref CREATE_STAGING_TABLE: String = format!("
        CREATE TEMP TABLE temp.fennecBookmarksStaging(
            id INTEGER PRIMARY KEY,
            guid TEXT NOT NULL UNIQUE,
            type TINYINT NOT NULL
                CHECK(type == {fennec_bookmark_type} OR type == {fennec_folder_type} OR type == {fennec_separator_type}),
            parent_guid TEXT,
            pos INT,
            title TEXT,
            bmkUri TEXT
                CHECK(type != {fennec_bookmark_type} OR validate_url(bmkUri) == bmkUri),
            keyword TEXT,
            tags TEXT,
            date_added INTEGER NOT NULL,
            modified INTEGER NOT NULL,
            isLocal TINYINT NOT NULL
        )",
        fennec_bookmark_type = FennecBookmarkType::Bookmark as u8,
        fennec_folder_type = FennecBookmarkType::Folder as u8,
        fennec_separator_type = FennecBookmarkType::Separator as u8,
    );


    static ref FIXUP_MOZ_BOOKMARKS: String = format!(
        // Is there anything else?
        "UPDATE main.moz_bookmarks SET
           syncStatus = {unknown},
           syncChangeCounter = 1,
           lastModified = IFNULL((SELECT stage.modified FROM temp.fennecBookmarksStaging stage
                                  WHERE stage.guid = main.moz_bookmarks.guid),
                                 lastModified)",
        unknown = SyncStatus::Unknown as u8
    );

    // Count Fennec bookmarks. We exclude guids we know we don't migrate, pinned
    // and deleted items because this count is used for success metrics.
    static ref COUNT_FENNEC_BOOKMARKS: &'static str =
        "SELECT COUNT(*) FROM fennec.bookmarks b
         WHERE GUID NOT IN ('pinned', 'tags')
         AND b.parent != -3
         AND NOT b.deleted"
    ;

    // Count Fenix bookmarks
    static ref COUNT_FENIX_BOOKMARKS: &'static str =
        "SELECT COUNT(*) FROM main.moz_bookmarks"
    ;
}

fn public_node_from_fennec_pinned(
    row: &rusqlite::Row<'_>,
) -> std::result::Result<PublicNode, rusqlite::Error> {
    Ok(PublicNode {
        node_type: BookmarkType::Bookmark,
        guid: row.get::<_, String>("guid")?.into(),
        parent_guid: None,
        position: row.get("position")?,
        date_added: row.get("created")?,
        last_modified: row.get("modified")?,
        title: row.get::<_, Option<String>>("title")?,
        url: row
            .get::<_, Option<String>>("url")?
            .and_then(|s| Url::parse(&s).ok()),
        ..Default::default()
    })
}

mod sql_fns {
    use crate::import::common::sql_fns::{sanitize_timestamp, sanitize_utf8, validate_url};
    use rusqlite::{functions::Context, Connection, Result};

    pub(super) fn define_functions(c: &Connection) -> Result<()> {
        c.create_scalar_function("normalize_root_guid", 1, true, normalize_root_guid)?;
        c.create_scalar_function("validate_url", 1, true, validate_url)?;
        c.create_scalar_function("sanitize_timestamp", 1, true, sanitize_timestamp)?;
        c.create_scalar_function("sanitize_utf8", 1, true, sanitize_utf8)?;
        Ok(())
    }

    #[inline(never)]
    pub fn normalize_root_guid(ctx: &Context<'_>) -> Result<String> {
        let guid = ctx.get::<String>(0)?;
        Ok(match guid.as_ref() {
            "places" => "root________".to_owned(),
            "menu" => "menu________".to_owned(),
            "toolbar" => "toolbar_____".to_owned(),
            "unfiled" => "unfiled_____".to_owned(),
            "mobile" => "mobile______".to_owned(),
            _ => guid,
        })
    }
}
