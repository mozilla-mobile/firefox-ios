/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::api::places_api::PlacesApi;
use crate::bookmark_sync::{
    store::{BookmarksStore, Merger},
    SyncedBookmarkKind,
};
use crate::error::*;
use crate::import::common::{attached_database, ExecuteOnDrop};
use crate::types::SyncStatus;
use rusqlite::{named_params, NO_PARAMS};
use sql_support::ConnExt;
use std::collections::HashMap;
use url::Url;

/// This import is used for iOS sync users migrating from `browser.db`-based
/// bookmark storage to the new rust-places store.
///
/// It is only used for users who are not connected to sync, as syncing
/// bookmarks will go through a more reliable, robust, and well-tested path, and
/// will migrate things that are unavailable on iOS due to the unfortunate
/// history of iOS bookmark sync (accurate last modified times, for example).
///
/// As a result, the goals of this import are as follows:
///
/// 1. Any locally created items must be persisted.
///
/// 2. Any items from remote machines that are visible to the user must be
///    persisted. (Note: before writing this, most of us believed that iOS wiped
///    its view of remote bookmarks on sync sign-out. Apparently it does not,
///    and its unclear if it ever did).
///
/// Additionally, it's worth noting that we assume that the iOS tree is
/// relatively well-formed. We do leverage `dogear` for the merge, to avoid
/// anything absurd, but for the most part the validation is fairly loose. If we
/// see anything we don't like (URL we don't allow, for example), we skip it.
///
/// ### Unsupported features
///
/// As such, the following things are explicitly not imported:
///
/// - Livemarks: We don't support them in our database anyway.
/// - Tombstones: This shouldn't matter for non-sync users.
/// - Queries: Not displayed or creatable in iOS UI, and only half-supported in
///   this database.
///
/// Some of this (queries, really) is a little unfortunate, since it's
/// theoretically possible for someone to care, but this should only happen for
/// users:
///
/// - Who once used sync, but no longer do.
/// - Who used this feature when they used sync.
/// - Who no longer have access to any firefoxes from when they were sync users,
///   other than this iOS device.
///
/// For these users, upon signing into sync once again, they will lose the data
/// in question.
///
/// ### Basic process
///
/// - Attach the iOS database.
/// - Slurp records into a temp table "iosBookmarksStaging" from iOS database.
///   - This is mostly done for convenience, and some performance benefits over
///     using a view or reading things into Rust (we'd rather not have to go
///     through `IncomingApplicator`, since it would require us forge
///     `sync15::Payload`s with this data).
/// - Add any entries to moz_places that are needed (in practice, they'll all be
///   needed, we don't yet store history for iOS).
/// - Fill mirror using iosBookmarksStaging.
/// - Fill mirror with tags from iosBookmarksStaging.
/// - Fill mirror structure using both iOS database and iosBookmarksStaging.
/// - Run dogear merge
/// - Use iosBookmarksStaging to fixup the data that was actually inserted.
/// - Update frecency for new items.
/// - Cleanup (Delete mirror and mirror structure, detach iOS database, etc).
pub fn import_ios_bookmarks(
    places_api: &PlacesApi,
    path: impl AsRef<std::path::Path>,
) -> Result<()> {
    let url = crate::util::ensure_url_path(path)?;
    do_import_ios_bookmarks(places_api, url)
}

fn do_import_ios_bookmarks(places_api: &PlacesApi, ios_db_file_url: Url) -> Result<()> {
    let conn = places_api.open_sync_connection()?;

    let scope = conn.begin_interrupt_scope();

    sql_fns::define_functions(&conn)?;

    // Not sure why, but apparently beginning a transaction sometimes
    // fails if we open the DB as read-only. Hopefully we don't
    // unintentionally write to it anywhere...
    // ios_db_file_url.query_pairs_mut().append_pair("mode", "ro");

    log::trace!("Attaching database {}", ios_db_file_url);
    let auto_detach = attached_database(&conn, &ios_db_file_url, "ios")?;

    let tx = conn.begin_transaction()?;

    let clear_mirror_on_drop = ExecuteOnDrop::new(&conn, WIPE_MIRROR.to_string());

    // Clear the mirror now, since we're about to fill it with data from the ios
    // connection.
    log::debug!("Clearing mirror to prepare for import");
    conn.execute_batch(&WIPE_MIRROR)?;
    scope.err_if_interrupted()?;

    log::debug!("Creating staging table");
    conn.execute_batch(&CREATE_STAGING_TABLE)?;

    log::debug!("Importing from iOS to staging table");
    conn.execute_batch(&POPULATE_STAGING)?;
    scope.err_if_interrupted()?;

    log::debug!("Populating missing entries in moz_places");
    conn.execute_batch(&FILL_MOZ_PLACES)?;
    scope.err_if_interrupted()?;

    log::debug!("Populating mirror");
    conn.execute_batch(&POPULATE_MIRROR)?;
    scope.err_if_interrupted()?;

    log::debug!("Populating mirror tags");
    populate_mirror_tags(&conn)?;
    scope.err_if_interrupted()?;

    // Ideally we could just do this right after `CREATE_AND_POPULATE_STAGING`,
    // but we have constraints on the mirror structure that prevent this (and
    // there's probably nothing bad that can happen in this case anyway). We
    // could turn use `PRAGMA defer_foreign_keys = true`, but since we commit
    // everything in one go, that seems harder to debug.
    log::debug!("Populating mirror structure");
    conn.execute_batch(&POPULATE_MIRROR_STRUCTURE)?;
    scope.err_if_interrupted()?;

    // log::debug!("Detaching iOS database");
    // drop(auto_detach);
    // scope.err_if_interrupted()?;

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

    log::info!("Successfully imported bookmarks!");

    auto_detach.execute_now()?;

    Ok(())
}

// If we must.
fn populate_mirror_tags(db: &crate::PlacesDb) -> Result<()> {
    use crate::storage::tags::{validate_tag, ValidatedTag};
    let mut tag_map: HashMap<String, Vec<i64>> = HashMap::new();
    {
        let mut stmt = db.prepare(
            "SELECT mirror.id, stage.tags
             FROM main.moz_bookmarks_synced mirror
             JOIN temp.iosBookmarksStaging stage USING(guid)
             -- iOS tags are JSON arrays of strings (or null).
             -- Both [] and null are allowed for 'no tags'
             WHERE stage.tags IS NOT NULL
               AND stage.tags != '[]'",
        )?;

        let mut rows = stmt.query(NO_PARAMS)?;
        while let Some(row) = rows.next()? {
            let id: i64 = row.get(0)?;
            let tags: String = row.get(1)?;
            let tag_vec = if let Ok(ts) = serde_json::from_str::<Vec<String>>(&tags) {
                ts
            } else {
                log::warn!("Ignoring bad `tags` entry");
                log::trace!("  entry had {:?}", tags);
                // Ignore garbage
                continue;
            };

            for tag in tag_vec {
                match validate_tag(&tag) {
                    ValidatedTag::Invalid(_) => {
                        log::warn!("Ignoring invalid tag");
                        log::trace!(" Bad tag was: {:?}", tag);
                    }
                    ValidatedTag::Original(t) | ValidatedTag::Normalized(t) => {
                        let ids = tag_map.entry(t.to_owned()).or_default();
                        ids.push(id);
                    }
                }
            }
        }
    }
    let tag_count = tag_map.len();
    let mut tagged_count = 0;
    for (tag, tagged_items) in tag_map {
        db.execute_named_cached(
            "INSERT OR IGNORE INTO main.moz_tags(tag, lastModified) VALUES(:tag, now())",
            named_params! { ":tag": tag },
        )?;

        let tag_id: i64 = db.query_row_and_then_named(
            "SELECT id FROM main.moz_tags WHERE tag = :tag",
            named_params! { ":tag": tag },
            |r| r.get(0),
            true,
        )?;
        tagged_count += tagged_items.len();
        for item_id in tagged_items {
            log::trace!("tagging {} with {}", item_id, tag);
            db.execute_named_cached(
                "INSERT INTO main.moz_bookmarks_synced_tag_relation(itemId, tagId) VALUES(:item_id, :tag_id)",
                named_params! { ":tag_id": tag_id, ":item_id": item_id },
            )?;
        }
    }
    log::debug!("Tagged {} items with {} tags", tagged_count, tag_count);

    Ok(())
}

#[derive(Clone, Copy, PartialEq, PartialOrd, Hash, Debug, Eq, Ord)]
#[repr(u8)]
pub enum IosBookmarkType {
    // https://github.com/mozilla-mobile/firefox-ios/blob/bd08cd4d/Storage/Bookmarks/Bookmarks.swift#L192
    Bookmark = 1,
    Folder = 2,
    Separator = 3,
    // Not supported
    // DynamicContainer = 4,
    // Livemark = 5,
    // Query = 6,
}

const ROOTS: &str =
    "('root________', 'menu________', 'toolbar_____', 'unfiled_____', 'mobile______')";

lazy_static::lazy_static! {
    static ref WIPE_MIRROR: String = format!(
        // Is omitting the roots right?
        "DELETE FROM main.moz_bookmarks_synced
           WHERE guid NOT IN {roots};
         DELETE FROM main.moz_bookmarks_synced_structure
           WHERE guid NOT IN {roots};
         UPDATE main.moz_bookmarks_synced
           SET needsMerge = 0;",
        roots = ROOTS,
    );
    // We omit:
    // - queries, since they don't show up in the iOS UI,
    // - livemarks, because we'd delete them
    // - dynamicContainers, because nobody knows what the hell they are.
    static ref IOS_VALID_TYPES: String = format!(
        "({bookmark_type}, {folder_type}, {separator_type})",
        bookmark_type = IosBookmarkType::Bookmark as u8,
        folder_type = IosBookmarkType::Folder as u8,
        separator_type = IosBookmarkType::Separator as u8,
    );

    // Insert any missing entries into moz_places that we'll need for this.
    static ref FILL_MOZ_PLACES: String = format!(
        "INSERT OR IGNORE INTO main.moz_places(guid, url, url_hash, frecency)
         SELECT IFNULL((SELECT p.guid FROM main.moz_places p
                        WHERE p.url_hash = hash(b.bmkUri) AND p.url = b.bmkUri),
                       generate_guid()),
                b.bmkUri,
                hash(b.bmkUri),
                -1
         FROM temp.iosBookmarksStaging b
         WHERE b.bmkUri IS NOT NULL
           AND b.type = {bookmark_type}",
        bookmark_type = IosBookmarkType::Bookmark as u8,
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
            b.parentid,
            b.modified,
            1, -- needsMerge
            1, -- VALIDITY_VALID
            0, -- isDeleted
            CASE b.type
                WHEN {ios_bookmark_type} THEN {bookmark_kind}
                WHEN {ios_folder_type} THEN {folder_kind}
                WHEN {ios_separator_type} THEN {separator_kind}
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
        FROM iosBookmarksStaging b",
        bookmark_kind = SyncedBookmarkKind::Bookmark as u8,
        folder_kind = SyncedBookmarkKind::Folder as u8,
        separator_kind = SyncedBookmarkKind::Separator as u8,

        ios_bookmark_type = IosBookmarkType::Bookmark as u8,
        ios_folder_type = IosBookmarkType::Folder as u8,
        ios_separator_type = IosBookmarkType::Separator as u8,

    );
}

const POPULATE_MIRROR_STRUCTURE: &str = "
REPLACE INTO main.moz_bookmarks_synced_structure(guid, parentGuid, position)
    SELECT structure.child, structure.parent, structure.idx FROM ios.bookmarksBufferStructure structure
    WHERE EXISTS(
        SELECT 1 FROM iosBookmarksStaging stage
        WHERE stage.isLocal = 0
            AND stage.guid = structure.child
    );
REPLACE INTO main.moz_bookmarks_synced_structure(guid, parentGuid, position)
    SELECT structure.child, structure.parent, structure.idx FROM ios.bookmarksLocalStructure structure
    WHERE EXISTS(
        SELECT 1 FROM iosBookmarksStaging stage
        WHERE stage.isLocal != 0
            AND stage.guid = structure.child
    );
";

lazy_static::lazy_static! {
    static ref POPULATE_STAGING: String = format!(
        "INSERT OR IGNORE INTO temp.iosBookmarksStaging(
            guid,
            type,
            parentid,
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
            b.guid,
            b.type,
            b.parentid,
            b.pos,
            b.title,
            CASE
                WHEN b.bmkUri IS NOT NULL
                    THEN validate_url(b.bmkUri)
                ELSE NULL
            END as uri,
            b.keyword,
            b.tags,
            sanitize_timestamp(b.date_added),
            sanitize_timestamp(b.server_modified),
            0
        FROM ios.bookmarksBuffer b
        WHERE NOT b.is_deleted
            -- Skip anything also in `local` (we can't use `replace`,
            -- since we use `IGNORE` to avoid inserting bad records)
            AND (
                (b.guid IN {roots})
                OR
                (b.guid NOT IN (SELECT l.guid FROM ios.bookmarksLocal l))
            )
            AND (b.type != {ios_bookmark_type} OR uri IS NOT NULL)
        ;
        INSERT OR IGNORE INTO temp.iosBookmarksStaging(
            guid,
            type,
            parentid,
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
            l.guid,
            l.type,
            l.parentid,
            l.pos,
            l.title,
            validate_url(l.bmkUri) as uri,
            l.keyword,
            l.tags,
            sanitize_timestamp(l.date_added),
            sanitize_timestamp(l.local_modified),
            1
        FROM ios.bookmarksLocal l
        WHERE NOT l.is_deleted
        AND uri IS NOT NULL
        ;",
        roots = ROOTS,
        ios_bookmark_type = IosBookmarkType::Bookmark as u8,
    );


    static ref CREATE_STAGING_TABLE: String = format!("
        CREATE TEMP TABLE temp.iosBookmarksStaging(
            id INTEGER PRIMARY KEY,
            guid TEXT NOT NULL UNIQUE,
            type TINYINT NOT NULL
                CHECK(type == {ios_bookmark_type} OR type == {ios_folder_type} OR type == {ios_separator_type}),
            parentid TEXT,
            pos INT,
            title TEXT,
            bmkUri TEXT
                CHECK(type != {ios_bookmark_type} OR validate_url(bmkUri) == bmkUri),
            keyword TEXT,
            tags TEXT,
            date_added INTEGER NOT NULL,
            modified INTEGER NOT NULL,
            isLocal TINYINT NOT NULL
        )",

            ios_bookmark_type = IosBookmarkType::Bookmark as u8,
            ios_folder_type = IosBookmarkType::Folder as u8,
            ios_separator_type = IosBookmarkType::Separator as u8,
    );


    static ref FIXUP_MOZ_BOOKMARKS: String = format!(
        // Is there anything else?
        "UPDATE main.moz_bookmarks SET
           syncStatus = {unknown},
           syncChangeCounter = 1,
           lastModified = IFNULL((SELECT stage.modified FROM temp.iosBookmarksStaging stage
                                  WHERE stage.guid = main.moz_bookmarks.guid),
                                 lastModified)",
        unknown = SyncStatus::Unknown as u8
    );
}

mod sql_fns {
    use crate::import::common::sql_fns::{sanitize_timestamp, validate_url};
    use rusqlite::{Connection, Result};

    pub(super) fn define_functions(c: &Connection) -> Result<()> {
        c.create_scalar_function("validate_url", 1, true, validate_url)?;
        c.create_scalar_function("sanitize_timestamp", 1, true, sanitize_timestamp)?;
        Ok(())
    }
}
