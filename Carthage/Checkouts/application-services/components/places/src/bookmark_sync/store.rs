/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use super::incoming::IncomingApplicator;
use super::record::{
    BookmarkItemRecord, BookmarkRecord, BookmarkRecordId, FolderRecord, QueryRecord,
    SeparatorRecord,
};
use super::{SyncedBookmarkKind, SyncedBookmarkValidity};
use crate::api::places_api::ConnectionType;
use crate::db::PlacesDb;
use crate::error::*;
use crate::frecency::{calculate_frecency, DEFAULT_FRECENCY_SETTINGS};
use crate::storage::{
    bookmarks::{
        bookmark_sync::{create_synced_bookmark_roots, reset, reset_meta},
        BookmarkRootGuid,
    },
    delete_pending_temp_tables, get_meta, put_meta,
};
use crate::types::{BookmarkType, SyncStatus, Timestamp};
use dogear::{
    self, AbortSignal, CompletionOps, Content, Item, MergedRoot, TelemetryEvent, Tree, UploadItem,
    UploadTombstone,
};
use rusqlite::{Row, NO_PARAMS};
use sql_support::{self, ConnExt, SqlInterruptScope};
use std::cell::RefCell;
use std::collections::HashMap;
use std::convert::TryFrom;
use std::fmt;
use std::result;
use sync15::{
    telemetry, CollSyncIds, CollectionRequest, IncomingChangeset, OutgoingChangeset, Payload,
    ServerTimestamp, Store, StoreSyncAssociation,
};
use sync_guid::Guid as SyncGuid;
pub const LAST_SYNC_META_KEY: &str = "bookmarks_last_sync_time";
// Note that all engines in this crate should use a *different* meta key
// for the global sync ID, because engines are reset individually.
pub const GLOBAL_SYNCID_META_KEY: &str = "bookmarks_global_sync_id";
pub const COLLECTION_SYNCID_META_KEY: &str = "bookmarks_sync_id";

/// The maximum number of URLs for which to recalculate frecencies at once.
/// This is a trade-off between write efficiency and transaction time: higher
/// maximums mean fewer write statements, but longer transactions, possibly
/// blocking writes from other connections.
const MAX_FRECENCIES_TO_RECALCULATE_PER_CHUNK: usize = 400;

/// Adapts an interruptee to a Dogear abort signal.
struct MergeInterruptee<'a, I>(&'a I);

impl<'a, I> AbortSignal for MergeInterruptee<'a, I>
where
    I: interrupt::Interruptee,
{
    #[inline]
    fn aborted(&self) -> bool {
        self.0.was_interrupted()
    }
}

pub struct BookmarksStore<'a> {
    pub db: &'a PlacesDb,
    interruptee: &'a SqlInterruptScope,
}

impl<'a> BookmarksStore<'a> {
    pub fn new(db: &'a PlacesDb, interruptee: &'a SqlInterruptScope) -> Self {
        assert_eq!(db.conn_type(), ConnectionType::Sync);
        Self { db, interruptee }
    }

    fn stage_incoming(
        &self,
        inbound: IncomingChangeset,
        incoming_telemetry: &mut telemetry::EngineIncoming,
    ) -> Result<ServerTimestamp> {
        let timestamp = inbound.timestamp;
        let mut tx = self.db.begin_transaction()?;

        let applicator = IncomingApplicator::new(&self.db);

        for incoming in inbound.changes {
            applicator.apply_payload(incoming.0, incoming.1)?;
            incoming_telemetry.applied(1);
            if tx.should_commit() {
                // Trigger frecency updates for all new origins.
                log::debug!("Updating origins for new synced URLs since last commit");
                delete_pending_temp_tables(&self.db)?;
            }
            tx.maybe_commit()?;
            self.interruptee.err_if_interrupted()?;
        }

        log::debug!("Updating origins for new synced URLs in last chunk");
        delete_pending_temp_tables(&self.db)?;

        tx.commit()?;
        Ok(timestamp)
    }

    fn has_changes(&self) -> Result<bool> {
        // In the first subquery, we check incoming items with needsMerge = true
        // except the tombstones who don't correspond to any local bookmark because
        // we don't store them yet, hence never "merged" (see bug 1343103).
        let sql = format!(
            "SELECT
                EXISTS (
                    SELECT 1
                    FROM moz_bookmarks_synced v
                    LEFT JOIN moz_bookmarks b ON v.guid = b.guid
                    WHERE v.needsMerge AND
                    (NOT v.isDeleted OR b.guid NOT NULL)
                ) OR EXISTS (
                    WITH RECURSIVE
                    {}
                    SELECT 1
                    FROM localItems
                    WHERE syncChangeCounter > 0
                ) OR EXISTS (
                    SELECT 1
                    FROM moz_bookmarks_deleted
                )
             AS hasChanges",
            LocalItemsFragment("localItems")
        );
        Ok(self
            .db
            .try_query_row(
                &sql,
                &[],
                |row| -> rusqlite::Result<_> { Ok(row.get::<_, bool>(0)?) },
                false,
            )?
            .unwrap_or(false))
    }

    /// Builds a temporary table with the merge states of all nodes in the merged
    /// tree, then updates the local tree to match the merged tree.
    ///
    /// Conceptually, we examine the merge state of each item, and either leave the
    /// item unchanged, upload the local side, apply the remote side, or apply and
    /// then reupload the remote side with a new structure.
    fn update_local_items_in_places<'t>(
        &self,
        now: Timestamp,
        ops: &CompletionOps<'t>,
    ) -> Result<()> {
        // Build a table of new and updated items.
        log::debug!("Staging apply remote item ops");
        sql_support::each_sized_chunk(
            &ops.apply_remote_items,
            sql_support::default_max_variable_number() / 3,
            |chunk, _| -> Result<()> {
                // CTEs in `WITH` clauses aren't indexed, so this query needs a
                // full table scan on `ops`. But that's okay; a separate temp
                // table for ops would also need a full scan. Note that we need
                // both the local _and_ remote GUIDs here, because we haven't
                // changed the local GUIDs yet.
                let sql = format!(
                    "WITH ops(mergedGuid, localGuid, remoteGuid, remoteType,
                              level) AS (
                         VALUES {ops}
                     )
                     INSERT INTO itemsToApply(mergedGuid, localId, remoteId,
                                              remoteGuid, newLevel, newKind,
                                              localDateAdded, remoteDateAdded,
                                              lastModified, oldTitle, newTitle,
                                              oldPlaceId, newPlaceId)
                     SELECT n.mergedGuid, b.id, v.id,
                            v.guid, n.level, n.remoteType,
                            b.dateAdded, v.dateAdded,
                            MAX(v.dateAdded, {now}), b.title, v.title,
                            b.fk, v.placeId
                     FROM ops n
                     JOIN moz_bookmarks_synced v ON v.guid = n.remoteGuid
                     LEFT JOIN moz_bookmarks b ON b.guid = n.localGuid",
                    ops = sql_support::repeat_display(chunk.len(), ",", |index, f| {
                        let op = &chunk[index];
                        write!(
                            f,
                            "(?, ?, ?, {}, {})",
                            SyncedBookmarkKind::from(op.remote_node().kind) as u8,
                            op.level
                        )
                    }),
                    now = now,
                );

                // We can't avoid allocating here, since we're binding four
                // parameters per descendant. Rust's `SliceConcatExt::concat`
                // is semantically equivalent, but requires a second allocation,
                // which we _can_ avoid by writing this out.
                let mut params = Vec::with_capacity(chunk.len() * 3);
                for op in chunk.iter() {
                    self.interruptee.err_if_interrupted()?;

                    let merged_guid = op.merged_node.guid.as_str();
                    params.push(Some(merged_guid));

                    let local_guid = op
                        .merged_node
                        .merge_state
                        .local_node()
                        .map(|node| node.guid.as_str());
                    params.push(local_guid);

                    let remote_guid = op.remote_node().guid.as_str();
                    params.push(Some(remote_guid));
                }

                self.db.execute(&sql, &params)?;
                Ok(())
            },
        )?;

        log::debug!("Staging change GUID ops");
        sql_support::each_sized_chunk(
            &ops.change_guids,
            sql_support::default_max_variable_number() / 2,
            |chunk, _| -> Result<()> {
                let sql = format!(
                    "INSERT INTO changeGuidOps(localGuid, mergedGuid,
                                               syncStatus, level, lastModified)
                     VALUES {}",
                    sql_support::repeat_display(chunk.len(), ",", |index, f| {
                        let op = &chunk[index];
                        // If only the local GUID changed, the item was deduped, so we
                        // can mark it as syncing. Otherwise, we changed an invalid
                        // GUID locally or remotely, so we leave its original sync
                        // status in place until we've uploaded it.
                        let sync_status = if op.merged_node.remote_guid_changed() {
                            None
                        } else {
                            Some(SyncStatus::Normal as u8)
                        };
                        write!(
                            f,
                            "(?, ?, {}, {}, {})",
                            NullableFragment(sync_status),
                            op.level,
                            now
                        )
                    }),
                );

                let mut params = Vec::with_capacity(chunk.len() * 2);
                for op in chunk.iter() {
                    self.interruptee.err_if_interrupted()?;

                    let local_guid = op.local_node().guid.as_str();
                    params.push(local_guid);

                    let merged_guid = op.merged_node.guid.as_str();
                    params.push(merged_guid);
                }

                self.db.execute(&sql, &params)?;
                Ok(())
            },
        )?;

        log::debug!("Staging apply new local structure ops");
        sql_support::each_sized_chunk(
            &ops.apply_new_local_structure,
            sql_support::default_max_variable_number() / 2,
            |chunk, _| -> Result<()> {
                let sql = format!(
                    "INSERT INTO applyNewLocalStructureOps(
                         mergedGuid, mergedParentGuid, position, level,
                         lastModified
                     )
                     VALUES {}",
                    sql_support::repeat_display(chunk.len(), ",", |index, f| {
                        let op = &chunk[index];
                        write!(f, "(?, ?, {}, {}, {})", op.position, op.level, now)
                    }),
                );

                let mut params = Vec::with_capacity(chunk.len() * 2);
                for op in chunk.iter() {
                    self.interruptee.err_if_interrupted()?;

                    let merged_guid = op.merged_node.guid.as_str();
                    params.push(merged_guid);

                    let merged_parent_guid = op.merged_parent_node.guid.as_str();
                    params.push(merged_parent_guid);
                }

                self.db.execute(&sql, &params)?;
                Ok(())
            },
        )?;

        log::debug!("Removing tombstones for revived items");
        sql_support::each_chunk_mapped(
            &ops.delete_local_tombstones,
            |op| op.guid().as_str(),
            |chunk, _| -> Result<()> {
                self.interruptee.err_if_interrupted()?;
                self.db.execute(
                    &format!(
                        "DELETE FROM moz_bookmarks_deleted
                         WHERE guid IN ({})",
                        sql_support::repeat_sql_vars(chunk.len())
                    ),
                    chunk,
                )?;
                Ok(())
            },
        )?;

        log::debug!("Inserting new tombstones for non-syncable and invalid items");
        sql_support::each_chunk_mapped(
            &ops.insert_local_tombstones,
            |op| op.remote_node().guid.as_str().to_owned(),
            |chunk, _| -> Result<()> {
                self.interruptee.err_if_interrupted()?;
                self.db.execute(
                    &format!(
                        "INSERT INTO moz_bookmarks_deleted(guid, dateRemoved)
                         VALUES {}",
                        sql_support::repeat_display(chunk.len(), ",", |_, f| write!(
                            f,
                            "(?, {})",
                            now
                        )),
                    ),
                    chunk,
                )?;
                Ok(())
            },
        )?;

        log::debug!("Flag frecencies for removed bookmark URLs as stale");
        sql_support::each_chunk_mapped(
            &ops.delete_local_items,
            |op| op.local_node().guid.as_str().to_owned(),
            |chunk, _| -> Result<()> {
                self.interruptee.err_if_interrupted()?;
                self.db.execute(
                    &format!(
                        "REPLACE INTO moz_places_stale_frecencies(
                             place_id, stale_at
                         )
                         SELECT b.fk, {now}
                         FROM moz_bookmarks b
                         WHERE b.guid IN ({vars})",
                        now = now,
                        vars = sql_support::repeat_sql_vars(chunk.len())
                    ),
                    chunk,
                )?;
                Ok(())
            },
        )?;

        log::debug!("Removing deleted items from Places");
        sql_support::each_chunk_mapped(
            &ops.delete_local_items,
            |op| op.local_node().guid.as_str().to_owned(),
            |chunk, _| -> Result<()> {
                self.interruptee.err_if_interrupted()?;
                self.db.execute(
                    &format!(
                        "DELETE FROM moz_bookmarks
                         WHERE guid IN ({})",
                        sql_support::repeat_sql_vars(chunk.len())
                    ),
                    chunk,
                )?;
                Ok(())
            },
        )?;

        log::debug!("Changing GUIDs");
        self.interruptee.err_if_interrupted()?;
        self.db.execute_batch("DELETE FROM changeGuidOps")?;

        log::debug!("Applying remote items");
        self.apply_remote_items(now)?;

        // Fires the `applyNewLocalStructure` trigger.
        log::debug!("Applying new local structure");
        self.interruptee.err_if_interrupted()?;
        self.db
            .execute_batch("DELETE FROM applyNewLocalStructureOps")?;

        log::debug!("Resetting change counters for items that shouldn't be uploaded");
        sql_support::each_chunk_mapped(
            &ops.set_local_merged,
            |op| op.merged_node.guid.as_str(),
            |chunk, _| -> Result<()> {
                self.interruptee.err_if_interrupted()?;
                self.db.execute(
                    &format!(
                        "UPDATE moz_bookmarks SET
                             syncChangeCounter = 0
                         WHERE guid IN ({})",
                        sql_support::repeat_sql_vars(chunk.len()),
                    ),
                    chunk,
                )?;
                Ok(())
            },
        )?;

        log::debug!("Bumping change counters for items that should be uploaded");
        sql_support::each_chunk_mapped(
            &ops.set_local_unmerged,
            |op| op.merged_node.guid.as_str(),
            |chunk, _| -> Result<()> {
                self.interruptee.err_if_interrupted()?;
                self.db.execute(
                    &format!(
                        "UPDATE moz_bookmarks SET
                             syncChangeCounter = 1
                         WHERE guid IN ({})",
                        sql_support::repeat_sql_vars(chunk.len()),
                    ),
                    chunk,
                )?;
                Ok(())
            },
        )?;

        log::debug!("Flagging applied remote items as merged");
        sql_support::each_chunk_mapped(
            &ops.set_remote_merged,
            |op| op.guid().as_str(),
            |chunk, _| -> Result<()> {
                self.interruptee.err_if_interrupted()?;
                self.db.execute(
                    &format!(
                        "UPDATE moz_bookmarks_synced SET
                             needsMerge = 0
                         WHERE guid IN ({})",
                        sql_support::repeat_sql_vars(chunk.len()),
                    ),
                    chunk,
                )?;
                Ok(())
            },
        )?;

        Ok(())
    }

    fn apply_remote_items(&self, now: Timestamp) -> Result<()> {
        log::debug!("Removing old tags");
        self.interruptee.err_if_interrupted()?;
        self.db.execute_batch(
            "DELETE FROM moz_tags_relation
             WHERE place_id IN (SELECT oldPlaceId FROM itemsToApply
                                WHERE oldPlaceId NOT NULL) OR
                   place_id IN (SELECT newPlaceId FROM itemsToApply
                                WHERE newPlaceId NOT NULL)",
        )?;

        // Insert and update items, temporarily using the Places root for new
        // items' parent IDs, and -1 for positions. We'll fix these up later,
        // when we apply the new local structure. This `INSERT` is a full table
        // scan on `itemsToApply`. The no-op `WHERE` clause is necessary to
        // avoid a parsing ambiguity.
        log::debug!("Upserting new items");
        self.interruptee.err_if_interrupted()?;
        self.db.execute_batch(&format!(
            "INSERT INTO moz_bookmarks(id, guid, parent,
                                       position, type, fk, title,
                                       dateAdded,
                                       lastModified,
                                       syncStatus, syncChangeCounter)
             SELECT localId, mergedGuid, (SELECT id FROM moz_bookmarks
                                          WHERE guid = '{root_guid}'),
                    -1, {type_fragment}, newPlaceId, newTitle,
                    /* Pick the older of the local and remote date added. We'll
                       weakly reupload any items with an older local date. */
                    MIN(IFNULL(localDateAdded, remoteDateAdded), remoteDateAdded),
                    /* The last modified date should always be newer than the date
                       added, so we pick the newer of the two here. */
                    MAX(lastModified, remoteDateAdded),
                    {sync_status}, 0
             FROM itemsToApply
             WHERE 1
             ON CONFLICT(id) DO UPDATE SET
               title = excluded.title,
               dateAdded = excluded.dateAdded,
               lastModified = excluded.lastModified,
               fk = excluded.fk",
            root_guid = BookmarkRootGuid::Root.as_guid().as_str(),
            type_fragment = ItemTypeFragment("newKind"),
            sync_status = SyncStatus::Normal as u8,
        ))?;

        log::debug!("Flagging frecencies for recalculation");
        self.interruptee.err_if_interrupted()?;
        self.db.execute_batch(&format!(
            "REPLACE INTO moz_places_stale_frecencies(place_id, stale_at)
             SELECT oldPlaceId, {now} FROM itemsToApply
             WHERE newKind = {bookmark_kind} AND (
                       oldPlaceId IS NULL <> newPlaceId IS NULL OR
                       oldPlaceId <> newPlaceId
                   )
             UNION ALL
             SELECT newPlaceId, {now} FROM itemsToApply
             WHERE newKind = {bookmark_kind} AND (
                       newPlaceId IS NULL <> oldPlaceId IS NULL OR
                       newPlaceId <> oldPlaceId
                   )",
            now = now,
            bookmark_kind = SyncedBookmarkKind::Bookmark as u8,
        ))?;

        log::debug!("Inserting new tags for new URLs");
        self.interruptee.err_if_interrupted()?;
        self.db.execute_batch(
            "INSERT OR IGNORE INTO moz_tags_relation(tag_id, place_id)
             SELECT r.tagId, n.newPlaceId
             FROM itemsToApply n
             JOIN moz_bookmarks_synced_tag_relation r ON r.itemId = n.remoteId",
        )?;

        Ok(())
    }

    /// Stores a snapshot of all locally changed items in a temporary table for
    /// upload. This is called from within the merge transaction, to ensure that
    /// changes made during the sync don't cause us to upload inconsistent
    /// records.
    ///
    /// Conceptually, `itemsToUpload` is a transient "view" of locally changed
    /// items. The local change counter is the persistent record of items that
    /// we need to upload, so, if upload is interrupted or fails, we'll stage
    /// the items again on the next sync.
    fn stage_items_to_upload(
        &self,
        upload_items: &[UploadItem<'_>],
        upload_tombstones: &[UploadTombstone<'_>],
    ) -> Result<()> {
        log::debug!("Cleaning up staged items left from last sync");
        self.interruptee.err_if_interrupted()?;
        self.db.execute_batch("DELETE FROM itemsToUpload")?;

        // Stage remotely changed items with older local creation dates. These are
        // tracked "weakly": if the upload is interrupted or fails, we won't
        // reupload the record on the next sync.
        log::debug!("Staging items with older local dates added");
        self.interruptee.err_if_interrupted()?;
        self.db.execute_batch(&format!(
            "INSERT OR IGNORE INTO itemsToUpload(id, guid, syncChangeCounter,
                                                 parentGuid, parentTitle, dateAdded,
                                                 kind, title, placeId, url,
                                                 keyword, position)
             {}
             JOIN itemsToApply n ON n.mergedGuid = b.guid
             WHERE n.localDateAdded < n.remoteDateAdded",
            UploadItemsFragment {
                alias: "b",
                remote_guid_column_name: "n.remoteGuid",
            },
        ))?;

        log::debug!("Staging remaining locally changed items for upload");
        sql_support::each_sized_chunk(
            upload_items,
            sql_support::default_max_variable_number() / 2,
            |chunk, _| -> Result<()> {
                let sql = format!(
                    "WITH ops(mergedGuid, remoteGuid) AS (VALUES {vars})
                     INSERT OR IGNORE INTO itemsToUpload(id, guid, syncChangeCounter,
                                                      parentGuid, parentTitle,
                                                      dateAdded, kind, title,
                                                      placeId, url, keyword,
                                                      position)
                     {upload_items_fragment}
                     JOIN ops n ON n.mergedGuid = b.guid",
                    vars =
                        sql_support::repeat_display(chunk.len(), ",", |_, f| write!(f, "(?, ?)")),
                    upload_items_fragment = UploadItemsFragment {
                        alias: "b",
                        remote_guid_column_name: "n.remoteGuid",
                    },
                );

                let mut params = Vec::with_capacity(chunk.len() * 2);
                for op in chunk.iter() {
                    self.interruptee.err_if_interrupted()?;

                    let merged_guid = op.merged_node.guid.as_str();
                    params.push(Some(merged_guid));

                    let remote_guid = op
                        .merged_node
                        .merge_state
                        .remote_node()
                        .map(|node| node.guid.as_str());
                    params.push(remote_guid);
                }

                self.db.execute(&sql, &params)?;
                Ok(())
            },
        )?;

        // Record the child GUIDs of locally changed folders, which we use to
        // populate the `children` array in the record.
        log::debug!("Staging structure to upload");
        self.interruptee.err_if_interrupted()?;
        self.db.execute_batch(
            "INSERT INTO structureToUpload(guid, parentId, position)
             SELECT b.guid, b.parent, b.position
             FROM moz_bookmarks b
             JOIN itemsToUpload o ON o.id = b.parent",
        )?;

        // Stage tags for outgoing bookmarks.
        log::debug!("Staging tags to upload");
        self.interruptee.err_if_interrupted()?;
        self.db.execute_batch(
            "INSERT INTO tagsToUpload(id, tag)
             SELECT o.id, t.tag
             FROM itemsToUpload o
             JOIN moz_tags_relation r ON r.place_id = o.placeId
             JOIN moz_tags t ON t.id = r.tag_id",
        )?;

        // Finally, stage tombstones for deleted items.
        log::debug!("Staging tombstones to upload");
        sql_support::each_chunk_mapped(
            upload_tombstones,
            |op| op.guid().as_str(),
            |chunk, _| -> Result<()> {
                self.interruptee.err_if_interrupted()?;
                self.db.execute(
                    &format!(
                        "INSERT OR IGNORE INTO itemsToUpload(
                         guid, syncChangeCounter, isDeleted
                     )
                     VALUES {}",
                        sql_support::repeat_display(chunk.len(), ",", |_, f| write!(
                            f,
                            "(?, 1, 1)"
                        )),
                    ),
                    chunk,
                )?;
                Ok(())
            },
        )?;

        Ok(())
    }

    /// Inflates Sync records for all staged outgoing items.
    fn fetch_outgoing_records(&self, timestamp: ServerTimestamp) -> Result<OutgoingChangeset> {
        let mut outgoing = OutgoingChangeset::new(self.collection_name(), timestamp);
        let mut child_record_ids_by_local_parent_id: HashMap<i64, Vec<BookmarkRecordId>> =
            HashMap::new();
        let mut tags_by_local_id: HashMap<i64, Vec<String>> = HashMap::new();

        let mut stmt = self.db.prepare(
            "SELECT parentId, guid FROM structureToUpload
             ORDER BY parentId, position",
        )?;
        let mut results = stmt.query(NO_PARAMS)?;
        while let Some(row) = results.next()? {
            self.interruptee.err_if_interrupted()?;
            let local_parent_id = row.get::<_, i64>("parentId")?;
            let child_guid = row.get::<_, SyncGuid>("guid")?;
            let child_record_ids = child_record_ids_by_local_parent_id
                .entry(local_parent_id)
                .or_default();
            child_record_ids.push(child_guid.into());
        }

        let mut stmt = self.db.prepare("SELECT id, tag FROM tagsToUpload")?;
        let mut results = stmt.query(NO_PARAMS)?;
        while let Some(row) = results.next()? {
            self.interruptee.err_if_interrupted()?;
            let local_id = row.get::<_, i64>("id")?;
            let tag = row.get::<_, String>("tag")?;
            let tags = tags_by_local_id.entry(local_id).or_default();
            tags.push(tag);
        }

        let mut stmt = self.db.prepare(
            "SELECT id, syncChangeCounter, guid, isDeleted, kind, keyword,
                    url, IFNULL(title, '') AS title, position, parentGuid,
                    IFNULL(parentTitle, '') AS parentTitle, dateAdded
             FROM itemsToUpload",
        )?;
        let mut results = stmt.query(NO_PARAMS)?;
        while let Some(row) = results.next()? {
            self.interruptee.err_if_interrupted()?;
            let guid = row.get::<_, SyncGuid>("guid")?;
            let is_deleted = row.get::<_, bool>("isDeleted")?;
            if is_deleted {
                outgoing.changes.push(Payload::new_tombstone(
                    BookmarkRecordId::from(guid).into_payload_id(),
                ));
                continue;
            }
            let parent_guid = row.get::<_, SyncGuid>("parentGuid")?;
            let parent_title = row.get::<_, String>("parentTitle")?;
            let date_added = row.get::<_, i64>("dateAdded")?;
            let record: BookmarkItemRecord = match SyncedBookmarkKind::from_u8(row.get("kind")?)? {
                SyncedBookmarkKind::Bookmark => {
                    let local_id = row.get::<_, i64>("id")?;
                    let title = row.get::<_, String>("title")?;
                    let url = row.get::<_, String>("url")?;
                    BookmarkRecord {
                        record_id: guid.into(),
                        parent_record_id: Some(parent_guid.into()),
                        parent_title: Some(parent_title),
                        date_added: Some(date_added),
                        has_dupe: true,
                        title: Some(title),
                        url: Some(url),
                        keyword: row.get::<_, Option<String>>("keyword")?,
                        tags: tags_by_local_id.remove(&local_id).unwrap_or_default(),
                    }
                    .into()
                }
                SyncedBookmarkKind::Query => {
                    let title = row.get::<_, String>("title")?;
                    let url = row.get::<_, String>("url")?;
                    QueryRecord {
                        record_id: guid.into(),
                        parent_record_id: Some(parent_guid.into()),
                        parent_title: Some(parent_title),
                        date_added: Some(date_added),
                        has_dupe: true,
                        title: Some(title),
                        url: Some(url),
                        tag_folder_name: None,
                    }
                    .into()
                }
                SyncedBookmarkKind::Folder => {
                    let title = row.get::<_, String>("title")?;
                    let local_id = row.get::<_, i64>("id")?;
                    let children = child_record_ids_by_local_parent_id
                        .remove(&local_id)
                        .unwrap_or_default();
                    FolderRecord {
                        record_id: guid.into(),
                        parent_record_id: Some(parent_guid.into()),
                        parent_title: Some(parent_title),
                        date_added: Some(date_added),
                        has_dupe: true,
                        title: Some(title),
                        children,
                    }
                    .into()
                }
                SyncedBookmarkKind::Livemark => continue,
                SyncedBookmarkKind::Separator => {
                    let position = row.get::<_, i64>("position")?;
                    SeparatorRecord {
                        record_id: guid.into(),
                        parent_record_id: Some(parent_guid.into()),
                        parent_title: Some(parent_title),
                        date_added: Some(date_added),
                        has_dupe: true,
                        position: Some(position),
                    }
                    .into()
                }
            };
            outgoing.changes.push(Payload::from_record(record)?);
        }

        Ok(outgoing)
    }

    /// Decrements the change counter, updates the sync status, and cleans up
    /// tombstones for successfully synced items. Sync calls this method at the
    /// end of each bookmark sync.
    fn push_synced_items(
        &self,
        uploaded_at: ServerTimestamp,
        records_synced: Vec<SyncGuid>,
    ) -> Result<()> {
        // Flag all successfully synced records as uploaded. This `UPDATE` fires
        // the `pushUploadedChanges` trigger, which updates local change
        // counters and writes the items back to the synced bookmarks table.
        let mut tx = self.db.begin_transaction()?;

        let guids = records_synced
            .into_iter()
            .map(|id| BookmarkRecordId::from_payload_id(id).into())
            .collect::<Vec<SyncGuid>>();
        sql_support::each_chunk(&guids, |chunk, _| -> Result<()> {
            self.db.execute(
                &format!(
                    "UPDATE itemsToUpload SET
                         uploadedAt = {uploaded_at}
                         WHERE guid IN ({values})",
                    uploaded_at = uploaded_at.as_millis(),
                    values = sql_support::repeat_sql_values(chunk.len())
                ),
                chunk,
            )?;
            tx.maybe_commit()?;
            self.interruptee.err_if_interrupted()?;
            Ok(())
        })?;

        // Fast-forward the last sync time, so that we don't download the
        // records we just uploaded on the next sync.
        put_meta(
            self.db,
            LAST_SYNC_META_KEY,
            &(uploaded_at.as_millis() as i64),
        )?;

        // Clean up.
        self.db.execute_batch("DELETE FROM itemsToUpload")?;
        tx.commit()?;

        Ok(())
    }

    pub(crate) fn update_frecencies(&self) -> Result<()> {
        let mut tx = self.db.begin_transaction()?;

        let mut frecencies = Vec::with_capacity(MAX_FRECENCIES_TO_RECALCULATE_PER_CHUNK);
        loop {
            let sql = format!(
                "SELECT place_id FROM moz_places_stale_frecencies
                 ORDER BY stale_at DESC
                 LIMIT {}",
                MAX_FRECENCIES_TO_RECALCULATE_PER_CHUNK
            );
            let mut stmt = self.db.prepare_maybe_cached(&sql, true)?;
            let mut results = stmt.query(NO_PARAMS)?;
            while let Some(row) = results.next()? {
                let place_id = row.get("place_id")?;
                // Frecency recalculation runs several statements, so check to
                // make sure we aren't interrupted before each calculation.
                self.interruptee.err_if_interrupted()?;
                let frecency = calculate_frecency(
                    &self.db,
                    &DEFAULT_FRECENCY_SETTINGS,
                    place_id,
                    Some(false),
                )?;
                frecencies.push((place_id, frecency));
            }
            if frecencies.is_empty() {
                break;
            }

            // Update all frecencies in one fell swoop...
            self.db.execute_batch(&format!(
                "WITH frecencies(id, frecency) AS (
                   VALUES {}
                 )
                 UPDATE moz_places SET
                   frecency = (SELECT frecency FROM frecencies f
                               WHERE f.id = id)
                 WHERE id IN (SELECT f.id FROM frecencies f)",
                sql_support::repeat_display(frecencies.len(), ",", |index, f| {
                    let (id, frecency) = frecencies[index];
                    write!(f, "({}, {})", id, frecency)
                })
            ))?;
            tx.maybe_commit()?;
            self.interruptee.err_if_interrupted()?;

            // ...And remove them from the stale table.
            self.db.execute_batch(&format!(
                "DELETE FROM moz_places_stale_frecencies
                 WHERE place_id IN ({})",
                sql_support::repeat_display(frecencies.len(), ",", |index, f| {
                    let (id, _) = frecencies[index];
                    write!(f, "{}", id)
                })
            ))?;
            tx.maybe_commit()?;
            self.interruptee.err_if_interrupted()?;

            // If the query returned fewer URLs than the maximum, we're done.
            // Otherwise, we might have more, so clear the ones we just
            // recalculated and fetch the next chunk.
            if frecencies.len() < MAX_FRECENCIES_TO_RECALCULATE_PER_CHUNK {
                break;
            }
            frecencies.clear();
        }

        tx.commit()?;

        Ok(())
    }

    /// Removes all sync metadata, such that the next sync is treated as a
    /// first sync. Unlike `wipe`, this keeps all local items, but clears
    /// all synced items and pending tombstones. This also forgets the last
    /// sync time, and either updates or removes the sync ID.
    pub(crate) fn reset(&self, assoc: &StoreSyncAssociation) -> Result<()> {
        match assoc {
            StoreSyncAssociation::Disconnected => {
                reset(self.db)?;
            }
            StoreSyncAssociation::Connected(ids) => {
                let tx = self.db.begin_transaction()?;
                reset_meta(self.db)?;
                put_meta(self.db, GLOBAL_SYNCID_META_KEY, &ids.global)?;
                put_meta(self.db, COLLECTION_SYNCID_META_KEY, &ids.coll)?;
                tx.commit()?;
            }
        }
        Ok(())
    }
}

impl<'a> Store for BookmarksStore<'a> {
    #[inline]
    fn collection_name(&self) -> std::borrow::Cow<'static, str> {
        "bookmarks".into()
    }

    fn apply_incoming(
        &self,
        inbound: Vec<IncomingChangeset>,
        telem: &mut telemetry::Engine,
    ) -> result::Result<OutgoingChangeset, failure::Error> {
        assert_eq!(inbound.len(), 1, "bookmarks only requests one item");
        let inbound = inbound.into_iter().next().unwrap();
        // Stage all incoming items.
        let mut incoming_telemetry = telemetry::EngineIncoming::new();
        let timestamp = self.stage_incoming(inbound, &mut incoming_telemetry)?;
        telem.incoming(incoming_telemetry);

        // write the timestamp now, so if we are interrupted merging or
        // creating outgoing changesets we don't need to re-download the same
        // records.
        put_meta(self.db, LAST_SYNC_META_KEY, &(timestamp.as_millis() as i64))?;

        // Merge.
        let mut merger = Merger::with_telemetry(&self, timestamp, telem);
        merger.merge()?;

        // Finally, stage outgoing items.
        let outgoing = self.fetch_outgoing_records(timestamp)?;
        Ok(outgoing)
    }

    fn sync_finished(
        &self,
        new_timestamp: ServerTimestamp,
        records_synced: Vec<SyncGuid>,
    ) -> result::Result<(), failure::Error> {
        self.push_synced_items(new_timestamp, records_synced)?;
        self.update_frecencies()?;
        self.db.pragma_update(None, "wal_checkpoint", &"PASSIVE")?;
        Ok(())
    }

    fn get_collection_requests(
        &self,
        server_timestamp: ServerTimestamp,
    ) -> result::Result<Vec<CollectionRequest>, failure::Error> {
        let since =
            ServerTimestamp(get_meta::<i64>(self.db, LAST_SYNC_META_KEY)?.unwrap_or_default());
        Ok(if since == server_timestamp {
            vec![]
        } else {
            vec![CollectionRequest::new(self.collection_name())
                .full()
                .newer_than(since)]
        })
    }

    fn get_sync_assoc(&self) -> result::Result<StoreSyncAssociation, failure::Error> {
        let global = get_meta(self.db, GLOBAL_SYNCID_META_KEY)?;
        let coll = get_meta(self.db, COLLECTION_SYNCID_META_KEY)?;
        Ok(if let (Some(global), Some(coll)) = (global, coll) {
            StoreSyncAssociation::Connected(CollSyncIds { global, coll })
        } else {
            StoreSyncAssociation::Disconnected
        })
    }

    fn reset(&self, assoc: &StoreSyncAssociation) -> result::Result<(), failure::Error> {
        BookmarksStore::reset(self, assoc)?;
        Ok(())
    }

    /// Erases all local items. Unlike `reset`, this keeps all synced items
    /// until the next sync, when they will be replaced with tombstones. This
    /// also preserves the last sync time.
    ///
    /// Conceptually, the next sync will merge an empty local tree, and a full
    /// remote tree.
    fn wipe(&self) -> result::Result<(), failure::Error> {
        let tx = self.db.begin_transaction()?;
        let sql = format!(
            "INSERT INTO moz_bookmarks_deleted(guid, dateRemoved)
             SELECT guid, now()
             FROM moz_bookmarks
             WHERE guid NOT IN {roots} AND
                   syncStatus = {sync_status};

             UPDATE moz_bookmarks SET
               syncChangeCounter = syncChangeCounter + 1
             WHERE guid IN {roots};

             DELETE FROM moz_bookmarks
             WHERE guid NOT IN {roots};",
            roots = RootsFragment(&[
                BookmarkRootGuid::Root,
                BookmarkRootGuid::Menu,
                BookmarkRootGuid::Mobile,
                BookmarkRootGuid::Toolbar,
                BookmarkRootGuid::Unfiled
            ]),
            sync_status = SyncStatus::Normal as u8
        );
        self.db.execute_batch(&sql)?;
        create_synced_bookmark_roots(self.db)?;
        tx.commit()?;
        Ok(())
    }
}

#[derive(Default)]
struct Driver {
    validation: RefCell<telemetry::Validation>,
}

impl dogear::Driver for Driver {
    fn generate_new_guid(&self, _invalid_guid: &dogear::Guid) -> dogear::Result<dogear::Guid> {
        Ok(SyncGuid::random().as_str().into())
    }

    fn record_telemetry_event(&self, event: TelemetryEvent) {
        // Record validation telemetry for remote trees.
        if let TelemetryEvent::FetchRemoteTree(stats) = event {
            self.validation
                .borrow_mut()
                .problem("orphans", stats.problems.orphans)
                .problem("misparentedRoots", stats.problems.misparented_roots)
                .problem(
                    "multipleParents",
                    stats.problems.multiple_parents_by_children,
                )
                .problem("missingParents", stats.problems.missing_parent_guids)
                .problem("nonFolderParents", stats.problems.non_folder_parent_guids)
                .problem(
                    "parentChildDisagreements",
                    stats.problems.parent_child_disagreements,
                )
                .problem("missingChildren", stats.problems.missing_children);
        }
    }
}

// The "merger", which is just a thin wrapper for dogear.
pub(crate) struct Merger<'a> {
    store: &'a BookmarksStore<'a>,
    remote_time: ServerTimestamp,
    local_time: Timestamp,
    // Used for where the merger is not the one which should be managing the
    // transaction, e.g. in the case of bookmarks import. The only impact this has
    // is on the `apply()` function. Always false unless the caller explicitly
    // turns it on, to avoid accidentally enabling unintentionally.
    external_transaction: bool,
    telem: Option<&'a mut telemetry::Engine>,
}

impl<'a> Merger<'a> {
    pub(crate) fn new(store: &'a BookmarksStore<'_>, remote_time: ServerTimestamp) -> Self {
        Self {
            store,
            remote_time,
            local_time: Timestamp::now(),
            external_transaction: false,
            telem: None,
        }
    }

    pub(crate) fn with_telemetry(
        store: &'a BookmarksStore<'_>,
        remote_time: ServerTimestamp,
        telem: &'a mut telemetry::Engine,
    ) -> Self {
        Self {
            store,
            remote_time,
            local_time: Timestamp::now(),
            external_transaction: false,
            telem: Some(telem),
        }
    }

    #[cfg(test)]
    fn with_localtime(
        store: &'a BookmarksStore<'_>,
        remote_time: ServerTimestamp,
        local_time: Timestamp,
    ) -> Self {
        Self {
            store,
            remote_time,
            local_time,
            external_transaction: false,
            telem: None,
        }
    }

    /// Prevent (or re-enable, in principal) using `begin_transaction` in `apply()`.
    ///
    /// The assumption is that if you call this, someone higher up the call_stack is
    /// managing the transaction at that point.
    pub(crate) fn set_external_transaction(&mut self, v: bool) {
        self.external_transaction = v;
    }

    pub(crate) fn merge(&mut self) -> Result<()> {
        use dogear::Store;
        if !self.store.has_changes()? {
            return Ok(());
        }
        // Merge and stage outgoing items via dogear.
        let driver = Driver::default();
        self.prepare()?;
        let result = self.merge_with_driver(&driver, &MergeInterruptee(self.store.interruptee));
        log::debug!("merge completed");

        // Record telemetry in all cases, even if the merge fails.
        if let Some(ref mut telem) = self.telem {
            telem.validation(driver.validation.into_inner());
        }
        result
    }

    /// Prepares synced bookmarks for merging.
    fn prepare(&self) -> Result<()> {
        // Like keywords, Sync associates tags with bookmarks, but Places
        // associates them with URLs. This means multiple bookmarks with the
        // same URL should have the same tags. In practice, different tags for
        // bookmarks with the same URL are some of the most common validation
        // errors we see.
        //
        // Unlike keywords, the relationship between URLs and tags in many-many:
        // multiple URLs can have the same tag, and a URL can have multiple
        // tags. So, to find mismatches, we need to compare the tags for each
        // URL with the tags for each item.
        //
        // We could fetch both lists of tags, sort them, and then compare them.
        // But there's a trick here: we're only interested in whether the tags
        // _match_, not the tags themselves. So we sum the tag IDs!
        //
        // This has two advantages: we don't have to sort IDs, since addition is
        // commutative, and we can compare two integers much more efficiently
        // than two string lists! If a bookmark has mismatched tags, the sum of
        // its tag IDs in `tagsByItemId` won't match the sum in `tagsByPlaceId`,
        // and we'll flag the item for reupload.
        log::debug!("Flagging tags with mismatched URLs for reupload");
        self.store.interruptee.err_if_interrupted()?;
        let sql = format!(
            "WITH
             tagsByPlaceId(placeId, tagIds) AS (
                 /* For multiple bookmarks with the same URL, each group will
                    have one tag per bookmark. So, if bookmarks A1, A2, and A3
                    have the same URL A with tag T, T will be in the group three
                    times. But we only want to count each tag once per URL, so
                    we use `SUM(DISTINCT)`. */
                 SELECT v.placeId, SUM(DISTINCT t.tagId)
                 FROM moz_bookmarks_synced v
                 JOIN moz_bookmarks_synced_tag_relation t ON t.itemId = v.id
                 WHERE v.placeId NOT NULL
                 GROUP BY v.placeId
             ),
             tagsByItemId(itemId, tagIds) AS (
                 /* But here, we can use a plain `SUM`, since we're grouping by
                    item ID, and an item can't have duplicate tags thanks to the
                    primary key on the relation table. */
                 SELECT t.itemId, SUM(t.tagId)
                 FROM moz_bookmarks_synced_tag_relation t
                 GROUP BY t.itemId
             )
             UPDATE moz_bookmarks_synced SET
                 validity = {reupload}
             WHERE validity = {valid} AND id IN (
                 SELECT v.id FROM moz_bookmarks_synced v
                 JOIN tagsByPlaceId u ON v.placeId = u.placeId
                 /* This left join is important: if A1 has tags and A2 doesn't,
                    we want to flag A2 for reupload. */
                 LEFT JOIN tagsByItemId t ON t.itemId = v.id
                 /* Unlike `<>`, `IS NOT` compares NULLs. */
                 WHERE t.tagIds IS NOT u.tagIds
             )",
            reupload = SyncedBookmarkValidity::Reupload as u8,
            valid = SyncedBookmarkValidity::Valid as u8,
        );
        self.store.db.execute_batch(&sql)?;

        Ok(())
    }

    /// Creates a local tree item from a row in the `localItems` CTE.
    fn local_row_to_item(&self, row: &Row<'_>) -> Result<(Item, Option<Content>)> {
        let guid = row.get::<_, SyncGuid>("guid")?;
        let url_href = row.get::<_, Option<String>>("url")?;
        let kind = match row.get::<_, BookmarkType>("type")? {
            BookmarkType::Bookmark => match url_href.as_ref() {
                Some(u) if u.starts_with("place:") => SyncedBookmarkKind::Query,
                _ => SyncedBookmarkKind::Bookmark,
            },
            BookmarkType::Folder => SyncedBookmarkKind::Folder,
            BookmarkType::Separator => SyncedBookmarkKind::Separator,
        };
        let mut item = Item::new(guid.as_str().into(), kind.into());
        // Note that this doesn't account for local clock skew.
        let age = self
            .local_time
            .duration_since(row.get::<_, Timestamp>("localModified")?)
            .unwrap_or_default();
        item.age = age.as_secs() as i64 * 1000 + i64::from(age.subsec_millis());
        item.needs_merge = row.get::<_, u32>("syncChangeCounter")? > 0;

        let content = if item.guid == dogear::ROOT_GUID {
            None
        } else {
            match row.get::<_, SyncStatus>("syncStatus")? {
                SyncStatus::Normal => None,
                _ => match kind {
                    SyncedBookmarkKind::Bookmark | SyncedBookmarkKind::Query => {
                        let title = row.get::<_, String>("title")?;
                        url_href.map(|url_href| Content::Bookmark { title, url_href })
                    }
                    SyncedBookmarkKind::Folder | SyncedBookmarkKind::Livemark => {
                        let title = row.get::<_, String>("title")?;
                        Some(Content::Folder { title })
                    }
                    SyncedBookmarkKind::Separator => Some(Content::Separator),
                },
            }
        };

        Ok((item, content))
    }

    /// Creates a remote tree item from a row in `moz_bookmarks_synced`.
    fn remote_row_to_item(&self, row: &Row<'_>) -> Result<(Item, Option<Content>)> {
        let guid = row.get::<_, SyncGuid>("guid")?;
        let kind = SyncedBookmarkKind::from_u8(row.get("kind")?)?;
        let mut item = Item::new(guid.as_str().into(), kind.into());
        // note that serverModified in this table is an int with ms, which isn't
        // the format of a ServerTimestamp - so we convert it into a number
        // of seconds before creating a ServerTimestamp and doing duration_since.
        let age = self
            .remote_time
            .duration_since(ServerTimestamp(row.get::<_, i64>("serverModified")?))
            .unwrap_or_default();
        item.age = age.as_secs() as i64 * 1000 + i64::from(age.subsec_millis());
        item.needs_merge = row.get("needsMerge")?;
        item.validity = SyncedBookmarkValidity::from_u8(row.get("validity")?)?.into();

        let content = if item.guid == dogear::ROOT_GUID || !item.needs_merge {
            None
        } else {
            match kind {
                SyncedBookmarkKind::Bookmark | SyncedBookmarkKind::Query => {
                    let title = row.get::<_, String>("title")?;
                    let url_href = row.get::<_, Option<String>>("url")?;
                    url_href.map(|url_href| Content::Bookmark { title, url_href })
                }
                SyncedBookmarkKind::Folder | SyncedBookmarkKind::Livemark => {
                    let title = row.get::<_, String>("title")?;
                    Some(Content::Folder { title })
                }
                SyncedBookmarkKind::Separator => Some(Content::Separator),
            }
        };

        Ok((item, content))
    }
}

impl<'a> dogear::Store for Merger<'a> {
    type Ok = ();
    type Error = Error;

    /// Builds a fully rooted, consistent tree from all local items and
    /// tombstones.
    fn fetch_local_tree(&self) -> Result<Tree> {
        let mut stmt = self.store.db.prepare(&format!(
            "SELECT guid, type, syncChangeCounter, syncStatus,
                    lastModified AS localModified,
                    NULL AS url
             FROM moz_bookmarks
             WHERE guid = '{root_guid}'",
            root_guid = BookmarkRootGuid::Root.as_guid().as_str(),
        ))?;
        let mut results = stmt.query(NO_PARAMS)?;
        let mut builder = match results.next()? {
            Some(row) => {
                let (item, _) = self.local_row_to_item(&row)?;
                Tree::with_root(item)
            }
            None => return Err(ErrorKind::Corruption(Corruption::InvalidLocalRoots).into()),
        };

        // Add items and contents to the builder, keeping track of their
        // structure in a separate map. We can't call `p.by_structure(...)`
        // after adding the item, because this query might return rows for
        // children before their parents. This approach also lets us scan
        // `moz_bookmarks` once, using the index on `(b.parent, b.position)`
        // to avoid a temp B-tree for the `ORDER BY`.
        let mut child_guids_by_parent_guid: HashMap<SyncGuid, Vec<dogear::Guid>> = HashMap::new();
        let mut stmt = self.store.db.prepare(&format!(
            "SELECT b.guid, p.guid AS parentGuid, b.type, b.syncChangeCounter,
                    b.syncStatus, b.lastModified AS localModified,
                    IFNULL(b.title, '') AS title,
                    {url_fragment} AS url
             FROM moz_bookmarks b
             JOIN moz_bookmarks p ON p.id = b.parent
             WHERE b.guid <> '{root_guid}'
             ORDER BY b.parent, b.position",
            url_fragment = UrlOrPlaceIdFragment::PlaceId("b.fk"),
            root_guid = BookmarkRootGuid::Root.as_guid().as_str(),
        ))?;
        let mut results = stmt.query(NO_PARAMS)?;

        while let Some(row) = results.next()? {
            self.store.interruptee.err_if_interrupted()?;

            let (item, content) = self.local_row_to_item(&row)?;

            let parent_guid = row.get::<_, SyncGuid>("parentGuid")?;
            child_guids_by_parent_guid
                .entry(parent_guid)
                .or_default()
                .push(item.guid.clone());

            let mut p = builder.item(item)?;
            if let Some(content) = content {
                p.content(content);
            }
        }

        // At this point, we've added entries for all items to the tree, so
        // we can add their structure info.
        for (parent_guid, child_guids) in &child_guids_by_parent_guid {
            for child_guid in child_guids {
                self.store.interruptee.err_if_interrupted()?;
                builder
                    .parent_for(child_guid)
                    .by_structure(&parent_guid.as_str().into())?;
            }
        }

        // Note tombstones for locally deleted items.
        let mut stmt = self
            .store
            .db
            .prepare("SELECT guid FROM moz_bookmarks_deleted")?;
        let mut results = stmt.query(NO_PARAMS)?;
        while let Some(row) = results.next()? {
            self.store.interruptee.err_if_interrupted()?;
            let guid = row.get::<_, SyncGuid>("guid")?;
            builder.deletion(guid.as_str().into());
        }

        let tree = Tree::try_from(builder)?;
        Ok(tree)
    }

    /// Builds a fully rooted tree from all synced items and tombstones.
    fn fetch_remote_tree(&self) -> Result<Tree> {
        // Unlike the local tree, items and structure are stored separately, so
        // we use three separate statements to fetch the root, its descendants,
        // and their structure.
        let sql = format!(
            "SELECT guid, serverModified, kind, needsMerge, validity
             FROM moz_bookmarks_synced
             WHERE NOT isDeleted AND
                   guid = '{root_guid}'",
            root_guid = BookmarkRootGuid::Root.as_guid().as_str()
        );
        let mut builder = self
            .store
            .db
            .try_query_row(
                &sql,
                &[],
                |row| -> Result<_> {
                    let (root, _) = self.remote_row_to_item(row)?;
                    Ok(Tree::with_root(root))
                },
                false,
            )?
            .ok_or_else(|| ErrorKind::Corruption(Corruption::InvalidSyncedRoots))?;
        builder.reparent_orphans_to(&dogear::UNFILED_GUID);

        let sql = format!(
            "SELECT v.guid, v.parentGuid, v.serverModified, v.kind,
                    IFNULL(v.title, '') AS title, v.needsMerge, v.validity,
                    v.isDeleted, {url_fragment} AS url
             FROM moz_bookmarks_synced v
             WHERE v.guid <> '{root_guid}'
             ORDER BY v.guid",
            url_fragment = UrlOrPlaceIdFragment::PlaceId("v.placeId"),
            root_guid = BookmarkRootGuid::Root.as_guid().as_str()
        );
        let mut stmt = self.store.db.prepare(&sql)?;
        let mut results = stmt.query(NO_PARAMS)?;
        while let Some(row) = results.next()? {
            self.store.interruptee.err_if_interrupted()?;

            let is_deleted = row.get::<_, bool>("isDeleted")?;
            if is_deleted {
                let needs_merge = row.get::<_, bool>("needsMerge")?;
                if !needs_merge {
                    // Ignore already-merged tombstones. These aren't persisted
                    // locally, so merging them is a no-op.
                    continue;
                }
                let guid = row.get::<_, SyncGuid>("guid")?;
                builder.deletion(guid.as_str().into());
            } else {
                let (item, content) = self.remote_row_to_item(&row)?;
                let mut p = builder.item(item)?;
                if let Some(content) = content {
                    p.content(content);
                }
                if let Some(parent_guid) = row.get::<_, Option<SyncGuid>>("parentGuid")? {
                    p.by_parent_guid(parent_guid.as_str().into())?;
                }
            }
        }

        let sql = format!(
            "SELECT guid, parentGuid FROM moz_bookmarks_synced_structure
             WHERE guid <> '{root_guid}'
             ORDER BY parentGuid, position",
            root_guid = BookmarkRootGuid::Root.as_guid().as_str()
        );
        let mut stmt = self.store.db.prepare(&sql)?;
        let mut results = stmt.query(NO_PARAMS)?;
        while let Some(row) = results.next()? {
            self.store.interruptee.err_if_interrupted()?;
            let guid = row.get::<_, SyncGuid>("guid")?;
            let parent_guid = row.get::<_, SyncGuid>("parentGuid")?;
            builder
                .parent_for(&guid.as_str().into())
                .by_children(&parent_guid.as_str().into())?;
        }

        let tree = Tree::try_from(builder)?;
        Ok(tree)
    }

    fn apply<'t>(&mut self, root: MergedRoot<'t>) -> Result<()> {
        let ops = root.completion_ops_with_signal(&MergeInterruptee(self.store.interruptee))?;

        if ops.is_empty() {
            // If we don't have any items to apply, upload, or delete,
            // no need to open a transaction at all.
            return Ok(());
        }

        let tx = if !self.external_transaction {
            Some(self.store.db.begin_transaction()?)
        } else {
            None
        };

        log::debug!("Updating local items in Places");
        self.store
            .update_local_items_in_places(self.local_time, &ops)?;

        log::debug!("Staging items to upload");
        self.store
            .stage_items_to_upload(&ops.upload_items, &ops.upload_tombstones)?;

        self.store.db.execute_batch("DELETE FROM itemsToApply;")?;
        if let Some(tx) = tx {
            tx.commit()?;
        }
        Ok(())
    }
}

/// A helper that formats an optional value so that it can be included in a SQL
/// statement. `None` values become SQL `NULL`s.
struct NullableFragment<T>(Option<T>);

impl<T> fmt::Display for NullableFragment<T>
where
    T: fmt::Display,
{
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match &self.0 {
            Some(v) => v.fmt(f),
            None => write!(f, "NULL"),
        }
    }
}

/// A helper that interpolates a SQL `CASE` expression for converting a synced
/// item kind to a local item type. The expression evaluates to `NULL` if the
/// kind is unknown.
struct ItemTypeFragment(&'static str);

impl fmt::Display for ItemTypeFragment {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "(CASE WHEN {col} IN ({bookmark_kind}, {query_kind})
                        THEN {bookmark_type}
                   WHEN {col} IN ({folder_kind}, {livemark_kind})
                        THEN {folder_type}
                   WHEN {col} = {separator_kind}
                        THEN {separator_type}
              END)",
            col = self.0,
            bookmark_kind = SyncedBookmarkKind::Bookmark as u8,
            query_kind = SyncedBookmarkKind::Query as u8,
            bookmark_type = BookmarkType::Bookmark as u8,
            folder_kind = SyncedBookmarkKind::Folder as u8,
            livemark_kind = SyncedBookmarkKind::Livemark as u8,
            folder_type = BookmarkType::Folder as u8,
            separator_kind = SyncedBookmarkKind::Separator as u8,
            separator_type = BookmarkType::Separator as u8,
        )
    }
}

/// Formats a `SELECT` statement for staging local items in the `itemsToUpload`
/// table.
struct UploadItemsFragment {
    /// The alias to use for the Places `moz_bookmarks` table.
    alias: &'static str,
    /// The name of the column containing the synced item's GUID.
    remote_guid_column_name: &'static str,
}

impl fmt::Display for UploadItemsFragment {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "SELECT {alias}.id, {alias}.guid, {alias}.syncChangeCounter,
                    p.guid AS parentGuid, p.title AS parentTitle,
                    {alias}.dateAdded, {kind_fragment} AS kind,
                    {alias}.title, h.id AS placeId, h.url,
                    (SELECT v.keyword FROM moz_bookmarks_synced v
                     WHERE v.guid = {remote_guid_column_name}),
                    {alias}.position
                FROM moz_bookmarks {alias}
                JOIN moz_bookmarks p ON p.id = {alias}.parent
                LEFT JOIN moz_places h ON h.id = {alias}.fk",
            alias = self.alias,
            kind_fragment =
                item_kind_fragment(self.alias, "type", UrlOrPlaceIdFragment::Url("h.url")),
            remote_guid_column_name = self.remote_guid_column_name,
        )
    }
}

/// A helper that interpolates a named SQL common table expression (CTE) for
/// local items. The CTE may be included in a `WITH RECURSIVE` clause.
struct LocalItemsFragment<'a>(&'a str);

impl<'a> fmt::Display for LocalItemsFragment<'a> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "{name}(id, guid, parentId, parentGuid, position, type, title, parentTitle,
                    placeId, dateAdded, lastModified, syncChangeCounter, level) AS (
             SELECT b.id, b.guid, 0, NULL, b.position, b.type, b.title, NULL,
                    b.fk, b.dateAdded, b.lastModified, b.syncChangeCounter, 0
             FROM moz_bookmarks b
             WHERE b.guid = '{root_guid}'
             UNION ALL
             SELECT b.id, b.guid, s.id, s.guid, b.position, b.type, b.title, s.title,
                    b.fk, b.dateAdded, b.lastModified, b.syncChangeCounter, s.level + 1
             FROM moz_bookmarks b
             JOIN {name} s ON s.id = b.parent)",
            name = self.0,
            root_guid = BookmarkRootGuid::Root.as_guid().as_str()
        )
    }
}

fn item_kind_fragment(
    table_name: &'static str,
    type_column_name: &'static str,
    url_or_place_id_fragment: UrlOrPlaceIdFragment,
) -> ItemKindFragment {
    ItemKindFragment {
        table_name,
        type_column_name,
        url_or_place_id_fragment,
    }
}

/// A helper that interpolates a SQL `CASE` expression for converting a local
/// item type to a synced item kind. The expression evaluates to `NULL` if the
/// type is unknown.
struct ItemKindFragment {
    /// The name of the Places bookmarks table.
    table_name: &'static str,
    /// The name of the column containing the Places item type.
    type_column_name: &'static str,
    /// The column containing the item's URL or Place ID.
    url_or_place_id_fragment: UrlOrPlaceIdFragment,
}

impl fmt::Display for ItemKindFragment {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "(CASE {table_name}.{type_column_name}
              WHEN {bookmark_type} THEN (
                  CASE substr({url}, 1, 6)
                  /* Queries are bookmarks with a 'place:' URL scheme. */
                  WHEN 'place:' THEN {query_kind}
                  ELSE {bookmark_kind}
                  END
              )
              WHEN {folder_type} THEN {folder_kind}
              WHEN {separator_type} THEN {separator_kind}
              END)",
            table_name = self.table_name,
            type_column_name = self.type_column_name,
            bookmark_type = BookmarkType::Bookmark as u8,
            url = self.url_or_place_id_fragment,
            query_kind = SyncedBookmarkKind::Query as u8,
            bookmark_kind = SyncedBookmarkKind::Bookmark as u8,
            folder_type = BookmarkType::Folder as u8,
            folder_kind = SyncedBookmarkKind::Folder as u8,
            separator_type = BookmarkType::Separator as u8,
            separator_kind = SyncedBookmarkKind::Separator as u8,
        )
    }
}

/// A helper that interpolates a SQL expression for querying a local item's
/// URL. Note that the `&'static str` for each variant specifies the _name of
/// the column_ containing the URL or ID, not the URL or ID itself.
enum UrlOrPlaceIdFragment {
    /// The name of the column containing the URL. This avoids a subquery if
    /// a column for the URL already exists in the query.
    Url(&'static str),
    /// The name of the column containing the Place ID. This writes out a
    /// subquery to look up the URL.
    PlaceId(&'static str),
}

impl fmt::Display for UrlOrPlaceIdFragment {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            UrlOrPlaceIdFragment::Url(s) => write!(f, "{}", s),
            UrlOrPlaceIdFragment::PlaceId(s) => {
                write!(f, "(SELECT h.url FROM moz_places h WHERE h.id = {})", s)
            }
        }
    }
}

/// A helper that interpolates a SQL list containing the given bookmark
/// root GUIDs.
struct RootsFragment<'a>(&'a [BookmarkRootGuid]);

impl<'a> fmt::Display for RootsFragment<'a> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("(")?;
        for (i, guid) in self.0.iter().enumerate() {
            if i != 0 {
                f.write_str(",")?;
            }
            write!(f, "'{}'", guid.as_str())?;
        }
        f.write_str(")")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::places_api::{test::new_mem_api, ConnectionType, PlacesApi};
    use crate::bookmark_sync::{store::BookmarksStore, tests::SyncedBookmarkItem};
    use crate::db::PlacesDb;
    use crate::storage::{
        bookmarks::{
            get_raw_bookmark, insert_bookmark, update_bookmark, BookmarkPosition,
            InsertableBookmark, UpdatableBookmark, USER_CONTENT_ROOTS,
        },
        history::frecency_stale_at,
        tags,
    };
    use crate::tests::{
        assert_json_tree as assert_local_json_tree, insert_json_tree as insert_local_json_tree,
    };
    use dogear::{Store as DogearStore, Validity};
    use pretty_assertions::assert_eq;
    use serde_json::{json, Value};
    use std::time::{Duration, SystemTime};
    use sync_guid::Guid;
    use url::Url;

    use sync15::{CollSyncIds, Payload};

    fn apply_incoming(conn: &PlacesDb, remote_time: ServerTimestamp, records_json: Value) {
        // suck records into the store.
        let interrupt_scope = conn.begin_interrupt_scope();
        let store = BookmarksStore::new(&conn, &interrupt_scope);

        let mut incoming = IncomingChangeset::new(store.collection_name(), remote_time);

        match records_json {
            Value::Array(records) => {
                for record in records {
                    let timestamp = record
                        .as_object()
                        .and_then(|r| r.get("modified"))
                        .map(|v| {
                            serde_json::from_value(v.clone())
                                .expect("Should deserialize server modified")
                        })
                        .unwrap_or(remote_time);
                    let payload = Payload::from_json(record).unwrap();
                    incoming.changes.push((payload, timestamp));
                }
            }
            Value::Object(ref r) => {
                let timestamp = r
                    .get("modified")
                    .map(|v| {
                        serde_json::from_value(v.clone())
                            .expect("Should deserialize server modified")
                    })
                    .unwrap_or(remote_time);
                let payload = Payload::from_json(records_json).unwrap();
                incoming.changes.push((payload, timestamp));
            }
            _ => panic!("unexpected json value"),
        }

        store
            .apply_incoming(vec![incoming], &mut telemetry::Engine::new("bookmarks"))
            .expect("Should apply incoming and stage outgoing records");

        let mut stmt = conn
            .prepare("SELECT guid FROM itemsToUpload")
            .expect("Should prepare statement to fetch uploaded GUIDs");
        let uploaded_guids: Vec<Guid> = stmt
            .query_and_then(NO_PARAMS, |row| -> rusqlite::Result<_> {
                Ok(row.get::<_, Guid>(0)?)
            })
            .expect("Should fetch uploaded GUIDs")
            .map(std::result::Result::unwrap)
            .collect();

        store
            .push_synced_items(remote_time, uploaded_guids)
            .expect("Should push synced changes back to the store");
    }

    fn assert_incoming_creates_local_tree(
        api: &PlacesApi,
        records_json: Value,
        local_folder: &SyncGuid,
        local_tree: Value,
    ) {
        let conn = api
            .open_sync_connection()
            .expect("should get a sync connection");
        apply_incoming(&conn, ServerTimestamp(0), records_json);
        assert_local_json_tree(&conn, local_folder, local_tree);
    }

    #[test]
    fn test_fetch_remote_tree() -> Result<()> {
        let _ = env_logger::try_init();
        let records = vec![
            json!({
                "id": "qqVTRWhLBOu3",
                "type": "bookmark",
                "parentid": "unfiled",
                "parentName": "Unfiled Bookmarks",
                "dateAdded": 1_381_542_355_843u64,
                "title": "The title",
                "bmkUri": "https://example.com",
                "tags": [],
            }),
            json!({
                "id": "unfiled",
                "type": "folder",
                "parentid": "places",
                "parentName": "",
                "dateAdded": 0,
                "title": "Unfiled Bookmarks",
                "children": ["qqVTRWhLBOu3"],
                "tags": [],
            }),
        ];

        let api = new_mem_api();
        let conn = api.open_sync_connection()?;

        // suck records into the store.
        let interrupt_scope = conn.begin_interrupt_scope();
        let store = BookmarksStore::new(&conn, &interrupt_scope);

        let mut incoming = IncomingChangeset::new(store.collection_name(), ServerTimestamp(0));

        for record in records {
            let payload = Payload::from_json(record).unwrap();
            incoming.changes.push((payload, ServerTimestamp(0)));
        }

        store
            .stage_incoming(incoming, &mut telemetry::EngineIncoming::new())
            .expect("Should apply incoming and stage outgoing records");

        let merger = Merger::new(&store, ServerTimestamp(0));

        let tree = merger.fetch_remote_tree()?;

        // should be each user root, plus the real root, plus the bookmark we added.
        assert_eq!(tree.guids().count(), USER_CONTENT_ROOTS.len() + 2);

        let node = tree
            .node_for_guid(&"qqVTRWhLBOu3".into())
            .expect("should exist");
        assert_eq!(node.needs_merge, true);
        assert_eq!(node.validity, Validity::Valid);
        assert_eq!(node.level(), 2);
        assert_eq!(node.is_syncable(), true);

        let node = tree
            .node_for_guid(&BookmarkRootGuid::Unfiled.as_guid().as_str().into())
            .expect("should exist");
        assert_eq!(node.needs_merge, true);
        assert_eq!(node.validity, Validity::Valid);
        assert_eq!(node.level(), 1);
        assert_eq!(node.is_syncable(), true);

        let node = tree
            .node_for_guid(&BookmarkRootGuid::Menu.as_guid().as_str().into())
            .expect("should exist");
        assert_eq!(node.needs_merge, false);
        assert_eq!(node.validity, Validity::Valid);
        assert_eq!(node.level(), 1);
        assert_eq!(node.is_syncable(), true);

        let node = tree
            .node_for_guid(&BookmarkRootGuid::Root.as_guid().as_str().into())
            .expect("should exist");
        assert_eq!(node.validity, Validity::Valid);
        assert_eq!(node.level(), 0);
        assert_eq!(node.is_syncable(), false);

        // We should have changes.
        assert_eq!(store.has_changes().unwrap(), true);
        Ok(())
    }

    #[test]
    fn test_fetch_local_tree() -> Result<()> {
        let now = SystemTime::now();
        let previously_ts: Timestamp = (now - Duration::new(10, 0)).into();
        let api = new_mem_api();
        let writer = api.open_connection(ConnectionType::ReadWrite)?;
        let syncer = api.open_sync_connection()?;

        writer
            .execute("UPDATE moz_bookmarks SET syncChangeCounter = 0", NO_PARAMS)
            .expect("should work");

        insert_local_json_tree(
            &writer,
            json!({
                "guid": &BookmarkRootGuid::Unfiled.as_guid(),
                "children": [
                    {
                        "guid": "bookmark1___",
                        "title": "the bookmark",
                        "url": "https://www.example.com/",
                        "last_modified": previously_ts,
                        "date_added": previously_ts,
                    },
                ]
            }),
        );

        let interrupt_scope = syncer.begin_interrupt_scope();
        let store = BookmarksStore::new(&syncer, &interrupt_scope);
        let merger = Merger::with_localtime(&store, ServerTimestamp(0), now.into());

        let tree = merger.fetch_local_tree()?;

        // should be each user root, plus the real root, plus the bookmark we added.
        assert_eq!(tree.guids().count(), USER_CONTENT_ROOTS.len() + 2);

        let node = tree
            .node_for_guid(&"bookmark1___".into())
            .expect("should exist");
        assert_eq!(node.needs_merge, true);
        assert_eq!(node.level(), 2);
        assert_eq!(node.is_syncable(), true);
        assert_eq!(node.age, 10000);

        let node = tree
            .node_for_guid(&BookmarkRootGuid::Unfiled.as_guid().as_str().into())
            .expect("should exist");
        assert_eq!(node.needs_merge, true);
        assert_eq!(node.level(), 1);
        assert_eq!(node.is_syncable(), true);

        let node = tree
            .node_for_guid(&BookmarkRootGuid::Menu.as_guid().as_str().into())
            .expect("should exist");
        assert_eq!(node.needs_merge, false);
        assert_eq!(node.level(), 1);
        assert_eq!(node.is_syncable(), true);

        let node = tree
            .node_for_guid(&BookmarkRootGuid::Root.as_guid().as_str().into())
            .expect("should exist");
        assert_eq!(node.needs_merge, false);
        assert_eq!(node.level(), 0);
        assert_eq!(node.is_syncable(), false);
        // hard to know the exact age of the root, but we know the max.
        let max_dur = SystemTime::now().duration_since(now).unwrap();
        let max_age = max_dur.as_secs() as i64 * 1000 + i64::from(max_dur.subsec_millis());
        assert!(node.age <= max_age);

        // We should have changes.
        assert_eq!(store.has_changes().unwrap(), true);
        Ok(())
    }

    #[test]
    fn test_apply_bookmark() {
        let api = new_mem_api();
        assert_incoming_creates_local_tree(
            &api,
            json!([{
                "id": "bookmark1___",
                "type": "bookmark",
                "parentid": "unfiled",
                "parentName": "Unfiled Bookmarks",
                "dateAdded": 1_381_542_355_843u64,
                "title": "Some bookmark",
                "bmkUri": "http://example.com",
            },
            {
                "id": "unfiled",
                "type": "folder",
                "parentid": "root",
                "dateAdded": 1_381_542_355_843u64,
                "title": "Unfiled",
                "children": ["bookmark1___"],
            }]),
            &BookmarkRootGuid::Unfiled.as_guid(),
            json!({"children" : [{"guid": "bookmark1___", "url": "http://example.com"}]}),
        );
        let reader = api
            .open_connection(ConnectionType::ReadOnly)
            .expect("Should open read-only connection");
        assert!(
            frecency_stale_at(&reader, &Url::parse("http://example.com").unwrap())
                .expect("Should check stale frecency")
                .is_some(),
            "Should mark frecency for bookmark URL as stale"
        );

        let writer = api
            .open_connection(ConnectionType::ReadWrite)
            .expect("Should open read-write connection");
        insert_local_json_tree(
            &writer,
            json!({
                "guid": &BookmarkRootGuid::Menu.as_guid(),
                "children": [
                    {
                        "guid": "bookmark2___",
                        "title": "2",
                        "url": "http://example.com/2",
                    }
                ],
            }),
        );
        assert_incoming_creates_local_tree(
            &api,
            json!([{
                "id": "menu",
                "type": "folder",
                "parentid": "places",
                "parentName": "",
                "dateAdded": 0,
                "title": "menu",
                "children": ["bookmark2___"],
            }, {
                "id": "bookmark2___",
                "type": "bookmark",
                "parentid": "menu",
                "parentName": "menu",
                "dateAdded": 1_381_542_355_843u64,
                "title": "2",
                "bmkUri": "http://example.com/2-remote",
            }]),
            &BookmarkRootGuid::Menu.as_guid(),
            json!({"children" : [{"guid": "bookmark2___", "url": "http://example.com/2-remote"}]}),
        );
        assert!(
            frecency_stale_at(&reader, &Url::parse("http://example.com/2").unwrap())
                .expect("Should check stale frecency for old URL")
                .is_some(),
            "Should mark frecency for old URL as stale"
        );
        assert!(
            frecency_stale_at(&reader, &Url::parse("http://example.com/2-remote").unwrap())
                .expect("Should check stale frecency for new URL")
                .is_some(),
            "Should mark frecency for new URL as stale"
        );

        let syncer = api
            .open_sync_connection()
            .expect("Should return Sync connection");
        let interrupt_scope = syncer.begin_interrupt_scope();
        let store = BookmarksStore::new(&syncer, &interrupt_scope);

        store.update_frecencies().expect("Should update frecencies");

        assert!(
            frecency_stale_at(&reader, &Url::parse("http://example.com").unwrap())
                .expect("Should check stale frecency")
                .is_none(),
            "Should recalculate frecency for first bookmark"
        );
        assert!(
            frecency_stale_at(&reader, &Url::parse("http://example.com/2").unwrap())
                .expect("Should check stale frecency for old URL")
                .is_none(),
            "Should recalculate frecency for old URL"
        );
        assert!(
            frecency_stale_at(&reader, &Url::parse("http://example.com/2-remote").unwrap())
                .expect("Should check stale frecency for new URL")
                .is_none(),
            "Should recalculate frecency for new URL"
        );
    }

    #[test]
    fn test_apply_complex_bookmark_tags() -> Result<()> {
        let api = new_mem_api();
        let writer = api.open_connection(ConnectionType::ReadWrite)?;

        // Insert two local bookmarks with the same URL A (so they'll have
        // identical tags) and a third with a different URL B, but one same
        // tag as A.
        let local_bookmarks = &[
            &InsertableBookmark {
                parent_guid: BookmarkRootGuid::Unfiled.as_guid(),
                position: BookmarkPosition::Append,
                date_added: None,
                last_modified: None,
                guid: Some("bookmarkAAA1".into()),
                url: Url::parse("http://example.com/a").unwrap(),
                title: Some("A1".into()),
            }
            .into(),
            &InsertableBookmark {
                parent_guid: BookmarkRootGuid::Menu.as_guid(),
                position: BookmarkPosition::Append,
                date_added: None,
                last_modified: None,
                guid: Some("bookmarkAAA2".into()),
                url: Url::parse("http://example.com/a").unwrap(),
                title: Some("A2".into()),
            }
            .into(),
            &InsertableBookmark {
                parent_guid: BookmarkRootGuid::Unfiled.as_guid(),
                position: BookmarkPosition::Append,
                date_added: None,
                last_modified: None,
                guid: Some("bookmarkBBBB".into()),
                url: Url::parse("http://example.com/b").unwrap(),
                title: Some("B".into()),
            }
            .into(),
        ];
        let local_tags = &[
            ("http://example.com/a", vec!["one", "two"]),
            (
                "http://example.com/b",
                // Local duplicate tags should be ignored.
                vec!["two", "three", "three", "four"],
            ),
        ];
        for bm in local_bookmarks {
            insert_bookmark(&writer, bm)?;
        }
        for (url, tags) in local_tags {
            let url = Url::parse(url)?;
            for t in tags.iter() {
                tags::tag_url(&writer, &url, t)?;
            }
        }

        // Now for some fun server data. Only B and C have problems; D and E
        // are fine, and shouldn't be reuploaded.
        let remote_records = json!([{
            // Change B's tags on the server, and duplicate `two` for good
            // measure. We should reupload B with only one `two` tag.
            "id": "bookmarkBBBB",
            "type": "bookmark",
            "parentid": "unfiled",
            "parentName": "Unfiled",
            "dateAdded": 1_381_542_355_843u64,
            "title": "B",
            "bmkUri": "http://example.com/b",
            "tags": ["two", "two", "three", "eight"],
        }, {
            // C is an example of bad data on the server: bookmarks with the
            // same URL should have the same tags, but C1/C2 have different tags
            // than C3. We should reupload all of them.
            "id": "bookmarkCCC1",
            "type": "bookmark",
            "parentid": "unfiled",
            "parentName": "Unfiled",
            "dateAdded": 1_381_542_355_843u64,
            "title": "C1",
            "bmkUri": "http://example.com/c",
            "tags": ["four", "five", "six"],
        }, {
            "id": "bookmarkCCC2",
            "type": "bookmark",
            "parentid": "menu",
            "parentName": "Menu",
            "dateAdded": 1_381_542_355_843u64,
            "title": "C2",
            "bmkUri": "http://example.com/c",
            "tags": ["four", "five", "six"],
        }, {
            "id": "bookmarkCCC3",
            "type": "bookmark",
            "parentid": "menu",
            "parentName": "Menu",
            "dateAdded": 1_381_542_355_843u64,
            "title": "C3",
            "bmkUri": "http://example.com/c",
            "tags": ["six", "six", "seven"],
        }, {
            // D has the same tags as C1/2, but a different URL. This is
            // perfectly fine, since URLs and tags are many-many! D also
            // isn't duplicated, so it'll be filtered out by the
            // `HAVING COUNT(*) > 1` clause.
            "id": "bookmarkDDDD",
            "type": "bookmark",
            "parentid": "unfiled",
            "parentName": "Unfiled",
            "dateAdded": 1_381_542_355_843u64,
            "title": "D",
            "bmkUri": "http://example.com/d",
            "tags": ["four", "five", "six"],
        }, {
            // E1 and E2 have the same URLs and the same tags, so we shouldn't
            // reupload either.
            "id": "bookmarkEEE1",
            "type": "bookmark",
            "parentid": "toolbar",
            "parentName": "Toolbar",
            "dateAdded": 1_381_542_355_843u64,
            "title": "E1",
            "bmkUri": "http://example.com/e",
            "tags": ["nine", "ten", "eleven"],
        }, {
            "id": "bookmarkEEE2",
            "type": "bookmark",
            "parentid": "mobile",
            "parentName": "Mobile",
            "dateAdded": 1_381_542_355_843u64,
            "title": "E2",
            "bmkUri": "http://example.com/e",
            "tags": ["nine", "ten", "eleven"],
        }, {
            // F1 and F2 have mismatched tags, but with a twist: F2 doesn't
            // have _any_ tags! We should only reupload F2.
            "id": "bookmarkFFF1",
            "type": "bookmark",
            "parentid": "toolbar",
            "parentName": "Toolbar",
            "dateAdded": 1_381_542_355_843u64,
            "title": "F1",
            "bmkUri": "http://example.com/f",
            "tags": ["twelve"],
        }, {
            "id": "bookmarkFFF2",
            "type": "bookmark",
            "parentid": "mobile",
            "parentName": "Mobile",
            "dateAdded": 1_381_542_355_843u64,
            "title": "F2",
            "bmkUri": "http://example.com/f",
        }, {
            "id": "unfiled",
            "type": "folder",
            "parentid": "root",
            "dateAdded": 1_381_542_355_843u64,
            "title": "Unfiled",
            "children": ["bookmarkBBBB", "bookmarkCCC1", "bookmarkDDDD"],
        }, {
            "id": "menu",
            "type": "folder",
            "parentid": "root",
            "dateAdded": 1_381_542_355_843u64,
            "title": "Menu",
            "children": ["bookmarkCCC2", "bookmarkCCC3"],
        }, {
            "id": "toolbar",
            "type": "folder",
            "parentid": "root",
            "dateAdded": 1_381_542_355_843u64,
            "title": "Toolbar",
            "children": ["bookmarkEEE1", "bookmarkFFF1"],
        }, {
            "id": "mobile",
            "type": "folder",
            "parentid": "root",
            "dateAdded": 1_381_542_355_843u64,
            "title": "Mobile",
            "children": ["bookmarkEEE2", "bookmarkFFF2"],
        }]);

        // Boilerplate to apply incoming records, since we want to check
        // outgoing record contents.
        let syncer = api.open_sync_connection()?;
        let interrupt_scope = syncer.begin_interrupt_scope();
        let store = BookmarksStore::new(&syncer, &interrupt_scope);
        let mut incoming = IncomingChangeset::new(store.collection_name(), ServerTimestamp(0));
        if let Value::Array(records) = remote_records {
            for record in records {
                let payload = Payload::from_json(record).unwrap();
                incoming.changes.push((payload, ServerTimestamp(0)));
            }
        } else {
            unreachable!("JSON records must be an array");
        }
        let mut outgoing = store
            .apply_incoming(vec![incoming], &mut telemetry::Engine::new("bookmarks"))
            .expect("Should apply incoming and stage outgoing records with tags");
        outgoing.changes.sort_by(|a, b| a.id.cmp(&b.id));

        // Verify that we applied all incoming records correctly.
        assert_local_json_tree(
            &writer,
            &BookmarkRootGuid::Root.as_guid(),
            json!({
                "guid": &BookmarkRootGuid::Root.as_guid(),
                "children": [{
                    "guid": &BookmarkRootGuid::Menu.as_guid(),
                    "children": [{
                        "guid": "bookmarkCCC2",
                        "title": "C2",
                        "url": "http://example.com/c",
                    }, {
                        "guid": "bookmarkCCC3",
                        "title": "C3",
                        "url": "http://example.com/c",
                    }, {
                        "guid": "bookmarkAAA2",
                        "title": "A2",
                        "url": "http://example.com/a",
                    }],
                }, {
                    "guid": &BookmarkRootGuid::Toolbar.as_guid(),
                    "children": [{
                        "guid": "bookmarkEEE1",
                        "title": "E1",
                        "url": "http://example.com/e",
                    }, {
                        "guid": "bookmarkFFF1",
                        "title": "F1",
                        "url": "http://example.com/f",
                    }],
                }, {
                    "guid": &BookmarkRootGuid::Unfiled.as_guid(),
                    "children": [{
                        "guid": "bookmarkBBBB",
                        "title": "B",
                        "url": "http://example.com/b",
                    }, {
                        "guid": "bookmarkCCC1",
                        "title": "C1",
                        "url": "http://example.com/c",
                    }, {
                        "guid": "bookmarkDDDD",
                        "title": "D",
                        "url": "http://example.com/d",
                    }, {
                        "guid": "bookmarkAAA1",
                        "title": "A1",
                        "url": "http://example.com/a",
                    }],
                }, {
                    "guid": &BookmarkRootGuid::Mobile.as_guid(),
                    "children": [{
                        "guid": "bookmarkEEE2",
                        "title": "E2",
                        "url": "http://example.com/e",
                    }, {
                        "guid": "bookmarkFFF2",
                        "title": "F2",
                        "url": "http://example.com/f",
                    }],
                }],
            }),
        );
        // And verify our local tags are correct, too.
        let expected_local_tags = &[
            ("http://example.com/a", vec!["one", "two"]),
            ("http://example.com/b", vec!["eight", "three", "two"]),
            ("http://example.com/c", vec!["five", "four", "seven", "six"]),
            ("http://example.com/d", vec!["five", "four", "six"]),
            ("http://example.com/e", vec!["eleven", "nine", "ten"]),
            ("http://example.com/f", vec!["twelve"]),
        ];
        for (href, expected) in expected_local_tags {
            let mut actual = tags::get_tags_for_url(&writer, &Url::parse(href).unwrap())?;
            actual.sort();
            assert_eq!(&actual, expected);
        }

        let expected_outgoing_ids = &[
            "bookmarkAAA1", // A is new locally.
            "bookmarkAAA2",
            "bookmarkBBBB", // B has a duplicate tag.
            "bookmarkCCC1", // C has mismatched tags.
            "bookmarkCCC2",
            "bookmarkCCC3",
            "bookmarkFFF2", // F2 is missing tags.
            "menu",         // Roots always get uploaded on the first sync.
            "mobile",
            "toolbar",
            "unfiled",
        ];
        assert_eq!(
            outgoing
                .changes
                .iter()
                .map(|p| p.id.as_str())
                .collect::<Vec<_>>(),
            expected_outgoing_ids,
            "Should upload new bookmarks and fix up tags",
        );

        // Now push the records back to the store, so we can check what we're
        // uploading.
        store
            .sync_finished(
                ServerTimestamp(0),
                expected_outgoing_ids.iter().map(SyncGuid::from).collect(),
            )
            .expect("Should push synced changes back to the store");

        // A and C should have the same URL and tags, and should be valid now.
        // Because the builder methods take a `&mut SyncedBookmarkItem`, and we
        // want to hang on to our base items for cloning later, we can't use
        // one-liners to create them.
        let mut synced_item_for_a = SyncedBookmarkItem::new();
        synced_item_for_a
            .validity(SyncedBookmarkValidity::Valid)
            .kind(SyncedBookmarkKind::Bookmark)
            .url(Some("http://example.com/a"))
            .tags(["one", "two"].iter().map(|&tag| tag.into()).collect());
        let mut synced_item_for_b = SyncedBookmarkItem::new();
        synced_item_for_b
            .validity(SyncedBookmarkValidity::Valid)
            .kind(SyncedBookmarkKind::Bookmark)
            .url(Some("http://example.com/b"))
            .tags(
                ["eight", "three", "two"]
                    .iter()
                    .map(|&tag| tag.into())
                    .collect(),
            )
            .parent_guid(Some(&BookmarkRootGuid::Unfiled.as_guid()))
            .title(Some("B"));
        let mut synced_item_for_c = SyncedBookmarkItem::new();
        synced_item_for_c
            .validity(SyncedBookmarkValidity::Valid)
            .kind(SyncedBookmarkKind::Bookmark)
            .url(Some("http://example.com/c"))
            .tags(
                ["five", "four", "seven", "six"]
                    .iter()
                    .map(|&tag| tag.into())
                    .collect(),
            );
        let mut synced_item_for_f = SyncedBookmarkItem::new();
        synced_item_for_f
            .validity(SyncedBookmarkValidity::Valid)
            .kind(SyncedBookmarkKind::Bookmark)
            .url(Some("http://example.com/f"))
            .tags(vec!["twelve".into()]);
        type Test<'a> = &'a [(
            &'static str,
            &'a SyncedBookmarkItem,
            Option<Box<dyn Fn(&mut SyncedBookmarkItem) -> &mut SyncedBookmarkItem>>,
        )];
        // A table-driven test to clean up some of the boilerplate. We clone
        // the base item for each test, and pass it to the boxed closure to set
        // additional properties.
        let expected_synced_items: Test<'_> = &[
            (
                "bookmarkAAA1",
                &synced_item_for_a,
                Some(Box::new(|a| {
                    a.parent_guid(Some(&BookmarkRootGuid::Unfiled.as_guid()))
                        .title(Some("A1"))
                })),
            ),
            (
                "bookmarkAAA2",
                &synced_item_for_a,
                Some(Box::new(|a| {
                    a.parent_guid(Some(&BookmarkRootGuid::Menu.as_guid()))
                        .title(Some("A2"))
                })),
            ),
            ("bookmarkBBBB", &synced_item_for_b, None),
            (
                "bookmarkCCC1",
                &synced_item_for_c,
                Some(Box::new(|c| {
                    c.parent_guid(Some(&BookmarkRootGuid::Unfiled.as_guid()))
                        .title(Some("C1"))
                })),
            ),
            (
                "bookmarkCCC2",
                &synced_item_for_c,
                Some(Box::new(|c| {
                    c.parent_guid(Some(&BookmarkRootGuid::Menu.as_guid()))
                        .title(Some("C2"))
                })),
            ),
            (
                "bookmarkCCC3",
                &synced_item_for_c,
                Some(Box::new(|c| {
                    c.parent_guid(Some(&BookmarkRootGuid::Menu.as_guid()))
                        .title(Some("C3"))
                })),
            ),
            (
                // We didn't reupload F1, but let's make sure it's still valid.
                "bookmarkFFF1",
                &synced_item_for_f,
                Some(Box::new(|f| {
                    f.parent_guid(Some(&BookmarkRootGuid::Toolbar.as_guid()))
                        .title(Some("F1"))
                })),
            ),
            (
                "bookmarkFFF2",
                &synced_item_for_f,
                Some(Box::new(|f| {
                    f.parent_guid(Some(&BookmarkRootGuid::Mobile.as_guid()))
                        .title(Some("F2"))
                })),
            ),
        ];
        for (guid, base, func) in expected_synced_items {
            let actual = SyncedBookmarkItem::get(&writer, &SyncGuid::from(guid))?
                .expect("Expected remote item should exist");
            let mut expected = SyncedBookmarkItem::clone(base);
            match func {
                Some(f) => assert_eq!(&actual, f(&mut expected)),
                None => assert_eq!(actual, expected),
            }
        }

        Ok(())
    }

    #[test]
    fn test_apply_bookmark_tags() -> Result<()> {
        let api = new_mem_api();
        let writer = api.open_connection(ConnectionType::ReadWrite)?;

        // Insert local item with tagged URL.
        insert_bookmark(
            &writer,
            &InsertableBookmark {
                parent_guid: BookmarkRootGuid::Unfiled.as_guid(),
                position: BookmarkPosition::Append,
                date_added: None,
                last_modified: None,
                guid: Some("bookmarkAAAA".into()),
                url: Url::parse("http://example.com/a").unwrap(),
                title: Some("A".into()),
            }
            .into(),
        )?;
        tags::tag_url(&writer, &Url::parse("http://example.com/a").unwrap(), "one")?;

        let mut tags_for_a =
            tags::get_tags_for_url(&writer, &Url::parse("http://example.com/a").unwrap())?;
        tags_for_a.sort();
        assert_eq!(tags_for_a, vec!["one".to_owned()]);

        assert_incoming_creates_local_tree(
            &api,
            json!([{
                "id": "bookmarkBBBB",
                "type": "bookmark",
                "parentid": "unfiled",
                "parentName": "Unfiled",
                "dateAdded": 1_381_542_355_843u64,
                "title": "B",
                "bmkUri": "http://example.com/b",
                "tags": ["one", "two"],
            }, {
                "id": "bookmarkCCCC",
                "type": "bookmark",
                "parentid": "unfiled",
                "parentName": "Unfiled",
                "dateAdded": 1_381_542_355_843u64,
                "title": "C",
                "bmkUri": "http://example.com/c",
                "tags": ["three"],
            }, {
                "id": "unfiled",
                "type": "folder",
                "parentid": "root",
                "dateAdded": 1_381_542_355_843u64,
                "title": "Unfiled",
                "children": ["bookmarkBBBB", "bookmarkCCCC"],
            }]),
            &BookmarkRootGuid::Unfiled.as_guid(),
            json!({"children" : [
                  {"guid": "bookmarkBBBB", "url": "http://example.com/b"},
                  {"guid": "bookmarkCCCC", "url": "http://example.com/c"},
                  {"guid": "bookmarkAAAA", "url": "http://example.com/a"},
            ]}),
        );

        let mut tags_for_a =
            tags::get_tags_for_url(&writer, &Url::parse("http://example.com/a").unwrap())?;
        tags_for_a.sort();
        assert_eq!(tags_for_a, vec!["one".to_owned()]);

        let mut tags_for_b =
            tags::get_tags_for_url(&writer, &Url::parse("http://example.com/b").unwrap())?;
        tags_for_b.sort();
        assert_eq!(tags_for_b, vec!["one".to_owned(), "two".to_owned()]);

        let mut tags_for_c =
            tags::get_tags_for_url(&writer, &Url::parse("http://example.com/c").unwrap())?;
        tags_for_c.sort();
        assert_eq!(tags_for_c, vec!["three".to_owned()]);

        let synced_item_for_a = SyncedBookmarkItem::get(&writer, &"bookmarkAAAA".into())
            .expect("Should fetch A")
            .expect("A should exist");
        assert_eq!(
            synced_item_for_a,
            *SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Valid)
                .kind(SyncedBookmarkKind::Bookmark)
                .parent_guid(Some(&BookmarkRootGuid::Unfiled.as_guid()))
                .title(Some("A"))
                .url(Some("http://example.com/a"))
                .tags(vec!["one".into()])
        );

        let synced_item_for_b = SyncedBookmarkItem::get(&writer, &"bookmarkBBBB".into())
            .expect("Should fetch B")
            .expect("B should exist");
        assert_eq!(
            synced_item_for_b,
            *SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Valid)
                .kind(SyncedBookmarkKind::Bookmark)
                .parent_guid(Some(&BookmarkRootGuid::Unfiled.as_guid()))
                .title(Some("B"))
                .url(Some("http://example.com/b"))
                .tags(vec!["one".into(), "two".into()])
        );

        Ok(())
    }

    #[test]
    fn test_apply_bookmark_keyword() -> Result<()> {
        let api = new_mem_api();

        let records = json!([{
            "id": "bookmarkAAAA",
            "type": "bookmark",
            "parentid": "unfiled",
            "parentName": "Unfiled",
            "dateAdded": 1_381_542_355_843u64,
            "title": "A",
            "bmkUri": "http://example.com/a?b=c&d=%s",
            "keyword": "ex",
        },
        {
            "id": "unfiled",
            "type": "folder",
            "parentid": "root",
            "dateAdded": 1_381_542_355_843u64,
            "title": "Unfiled",
            "children": ["bookmarkAAAA"],
        }]);

        let db = api
            .open_sync_connection()
            .expect("Should open Sync connection");

        let tx = db.begin_transaction()?;
        let applicator = IncomingApplicator::new(&db);

        if let Value::Array(records) = records {
            for record in records {
                let payload = Payload::from_json(record).unwrap();
                applicator.apply_payload(payload, ServerTimestamp(0))?;
            }
        } else {
            unreachable!("JSON records must be an array");
        }

        tx.commit()?;

        // Flag the bookmark with the keyword for reupload, so that we can
        // ensure the keyword is round-tripped correctly.
        db.execute_named(
            "UPDATE moz_bookmarks_synced SET
                 validity = :validity
             WHERE guid = :guid",
            rusqlite::named_params! {
                ":validity": SyncedBookmarkValidity::Reupload,
                ":guid": SyncGuid::from("bookmarkAAAA"),
            },
        )?;

        let interrupt_scope = db.begin_interrupt_scope();
        let store = BookmarksStore::new(&db, &interrupt_scope);

        let mut merger = Merger::new(&store, ServerTimestamp(0));
        merger.merge()?;

        assert_local_json_tree(
            &db,
            &BookmarkRootGuid::Unfiled.as_guid(),
            json!({"children" : [{"guid": "bookmarkAAAA", "url": "http://example.com/a?b=c&d=%s"}]}),
        );

        let outgoing = store.fetch_outgoing_records(ServerTimestamp(0))?;
        let record_for_a = outgoing
            .changes
            .iter()
            .find(|payload| payload.id == "bookmarkAAAA")
            .expect("Should reupload A");
        assert_eq!(record_for_a.data["bmkUri"], "http://example.com/a?b=c&d=%s");
        assert_eq!(record_for_a.data["keyword"], "ex");

        Ok(())
    }

    #[test]
    fn test_apply_query() {
        // should we add some more query variations here?
        let api = new_mem_api();
        assert_incoming_creates_local_tree(
            &api,
            json!([{
                "id": "query1______",
                "type": "query",
                "parentid": "unfiled",
                "parentName": "Unfiled Bookmarks",
                "dateAdded": 1_381_542_355_843u64,
                "title": "Some query",
                "bmkUri": "place:tag=foo",
            },
            {
                "id": "unfiled",
                "type": "folder",
                "parentid": "root",
                "dateAdded": 1_381_542_355_843u64,
                "title": "Unfiled",
                "children": ["query1______"],
            }]),
            &BookmarkRootGuid::Unfiled.as_guid(),
            json!({"children" : [{"guid": "query1______", "url": "place:tag=foo"}]}),
        );
        let reader = api
            .open_connection(ConnectionType::ReadOnly)
            .expect("Should open read-only connection");
        assert!(
            frecency_stale_at(&reader, &Url::parse("place:tag=foo").unwrap())
                .expect("Should check stale frecency")
                .is_none(),
            "Should not mark frecency for queries as stale"
        );
    }

    #[test]
    fn test_apply() -> Result<()> {
        let api = new_mem_api();
        let writer = api.open_connection(ConnectionType::ReadWrite)?;
        let syncer = api.open_sync_connection()?;

        syncer
            .execute("UPDATE moz_bookmarks SET syncChangeCounter = 0", NO_PARAMS)
            .expect("should work");

        insert_local_json_tree(
            &writer,
            json!({
                "guid": &BookmarkRootGuid::Unfiled.as_guid(),
                "children": [
                    {
                        "guid": "bookmarkAAAA",
                        "title": "A",
                        "url": "http://example.com/a",
                    },
                    {
                        "guid": "bookmarkBBBB",
                        "title": "B",
                        "url": "http://example.com/b",
                    },
                ]
            }),
        );
        tags::tag_url(
            &writer,
            &Url::parse("http://example.com/a").expect("Should parse URL for A"),
            "baz",
        )
        .expect("Should tag A");

        let records = vec![
            json!({
                "id": "bookmarkCCCC",
                "type": "bookmark",
                "parentid": "menu",
                "parentName": "menu",
                "dateAdded": 1_552_183_116_885u64,
                "title": "C",
                "bmkUri": "http://example.com/c",
                "tags": ["foo", "bar"],
            }),
            json!({
                "id": "menu",
                "type": "folder",
                "parentid": "places",
                "parentName": "",
                "dateAdded": 0,
                "title": "menu",
                "children": ["bookmarkCCCC"],
            }),
        ];

        let interrupt_scope = syncer.begin_interrupt_scope();
        let store = BookmarksStore::new(&syncer, &interrupt_scope);

        let mut incoming = IncomingChangeset::new(store.collection_name(), ServerTimestamp(0));
        for record in records {
            let payload = Payload::from_json(record).unwrap();
            incoming.changes.push((payload, ServerTimestamp(0)));
        }

        let mut outgoing = store
            .apply_incoming(vec![incoming], &mut telemetry::Engine::new("bookmarks"))
            .expect("Should apply incoming and stage outgoing records");
        outgoing.changes.sort_by(|a, b| a.id.cmp(&b.id));
        assert_eq!(
            outgoing
                .changes
                .iter()
                .map(|p| p.id.as_str())
                .collect::<Vec<_>>(),
            vec!["bookmarkAAAA", "bookmarkBBBB", "unfiled",]
        );
        let record_for_a = outgoing
            .changes
            .iter()
            .find(|p| p.id == "bookmarkAAAA")
            .expect("Should upload A");
        assert_eq!(
            record_for_a.data["tags"]
                .as_array()
                .expect("Should upload tags for A"),
            &["baz"]
        );

        assert_local_json_tree(
            &writer,
            &BookmarkRootGuid::Root.as_guid(),
            json!({
                "guid": &BookmarkRootGuid::Root.as_guid(),
                "children": [
                    {
                        "guid": &BookmarkRootGuid::Menu.as_guid(),
                        "children": [
                            {
                                "guid": "bookmarkCCCC",
                                "title": "C",
                                "url": "http://example.com/c",
                                "date_added": Timestamp(1_552_183_116_885),
                            },
                        ],
                    },
                    {
                        "guid": &BookmarkRootGuid::Toolbar.as_guid(),
                        "children": [],
                    },
                    {
                        "guid": &BookmarkRootGuid::Unfiled.as_guid(),
                        "children": [
                            {
                                "guid": "bookmarkAAAA",
                                "title": "A",
                                "url": "http://example.com/a",
                            },
                            {
                                "guid": "bookmarkBBBB",
                                "title": "B",
                                "url": "http://example.com/b",
                            },
                        ],
                    },
                    {
                        "guid": &BookmarkRootGuid::Mobile.as_guid(),
                        "children": [],
                    },
                ],
            }),
        );

        // We haven't finished the sync yet, so all local change counts for
        // items to upload should still be > 0.
        let guid_for_a: SyncGuid = "bookmarkAAAA".into();
        let info_for_a = get_raw_bookmark(&writer, &guid_for_a)
            .expect("Should fetch info for A")
            .unwrap();
        assert_eq!(info_for_a.sync_change_counter, 2);
        let info_for_unfiled = get_raw_bookmark(&writer, &BookmarkRootGuid::Unfiled.as_guid())
            .expect("Should fetch info for unfiled")
            .unwrap();
        assert_eq!(info_for_unfiled.sync_change_counter, 2);

        store
            .sync_finished(
                ServerTimestamp(0),
                vec![
                    "bookmarkAAAA".into(),
                    "bookmarkBBBB".into(),
                    "unfiled".into(),
                ],
            )
            .expect("Should push synced changes back to the store");

        let info_for_a = get_raw_bookmark(&writer, &guid_for_a)
            .expect("Should fetch info for A")
            .unwrap();
        assert_eq!(info_for_a.sync_change_counter, 0);
        let info_for_unfiled = get_raw_bookmark(&writer, &BookmarkRootGuid::Unfiled.as_guid())
            .expect("Should fetch info for unfiled")
            .unwrap();
        assert_eq!(info_for_unfiled.sync_change_counter, 0);

        let mut tags_for_c = tags::get_tags_for_url(
            &writer,
            &Url::parse("http://example.com/c").expect("Should parse URL for C"),
        )
        .expect("Should return tags for C");
        tags_for_c.sort();
        assert_eq!(tags_for_c, &["bar", "foo"]);

        Ok(())
    }

    #[test]
    fn test_keywords() -> Result<()> {
        use crate::storage::bookmarks::bookmarks_get_url_for_keyword;

        let api = new_mem_api();
        let writer = api.open_connection(ConnectionType::ReadWrite)?;
        let syncer = api.open_sync_connection()?;

        let records = vec![
            json!({
                "id": "toolbar",
                "type": "folder",
                "parentid": "places",
                "parentName": "",
                "dateAdded": 0,
                "title": "toolbar",
                "children": ["bookmarkAAAA"],
            }),
            json!({
                "id": "bookmarkAAAA",
                "type": "bookmark",
                "parentid": "toolbar",
                "parentName": "toolbar",
                "dateAdded": 1_552_183_116_885u64,
                "title": "A",
                "bmkUri": "http://example.com/a/%s",
                "keyword": "a",
            }),
        ];

        let interrupt_scope = syncer.begin_interrupt_scope();
        let store = BookmarksStore::new(&syncer, &interrupt_scope);

        let mut incoming = IncomingChangeset::new(store.collection_name(), ServerTimestamp(0));
        for record in records {
            let payload = Payload::from_json(record).unwrap();
            incoming.changes.push((payload, ServerTimestamp(0)));
        }

        let outgoing = store
            .apply_incoming(vec![incoming], &mut telemetry::Engine::new("bookmarks"))
            .expect("Should apply incoming records");
        let mut outgoing_ids = outgoing
            .changes
            .iter()
            .map(|p| p.id.clone())
            .collect::<Vec<_>>();
        outgoing_ids.sort();
        assert_eq!(outgoing_ids, &["menu", "mobile", "toolbar", "unfiled"],);

        assert_eq!(
            bookmarks_get_url_for_keyword(&writer, "a")?,
            Some(Url::parse("http://example.com/a/%s")?)
        );

        store
            .sync_finished(ServerTimestamp(0), outgoing_ids)
            .expect("Should push synced changes back to the store");

        update_bookmark(
            &writer,
            &"bookmarkAAAA".into(),
            &UpdatableBookmark {
                title: Some("A (local)".into()),
                ..UpdatableBookmark::default()
            }
            .into(),
        )?;

        let outgoing = store
            .apply_incoming(
                vec![IncomingChangeset::new(
                    store.collection_name(),
                    ServerTimestamp(1000),
                )],
                &mut telemetry::Engine::new("bookmarks"),
            )
            .expect("Should fetch outgoing records after making local changes");
        assert_eq!(outgoing.changes.len(), 1);
        assert_eq!(outgoing.changes[0].id, "bookmarkAAAA");
        assert_eq!(outgoing.changes[0].data["keyword"], "a");
        assert_eq!(
            outgoing.changes[0].data["bmkUri"],
            "http://example.com/a/%s"
        );

        Ok(())
    }

    #[test]
    fn test_wipe() -> Result<()> {
        let api = new_mem_api();
        let writer = api.open_connection(ConnectionType::ReadWrite)?;
        let syncer = api.open_sync_connection()?;

        let records = vec![
            json!({
                "id": "toolbar",
                "type": "folder",
                "parentid": "places",
                "parentName": "",
                "dateAdded": 0,
                "title": "toolbar",
                "children": ["folderAAAAAA"],
            }),
            json!({
                "id": "folderAAAAAA",
                "type": "folder",
                "parentid": "toolbar",
                "parentName": "toolbar",
                "dateAdded": 0,
                "title": "A",
                "children": ["bookmarkBBBB"],
            }),
            json!({
                "id": "bookmarkBBBB",
                "type": "bookmark",
                "parentid": "folderAAAAAA",
                "parentName": "A",
                "dateAdded": 0,
                "title": "A",
                "bmkUri": "http://example.com/a",
            }),
            json!({
                "id": "menu",
                "type": "folder",
                "parentid": "places",
                "parentName": "",
                "dateAdded": 0,
                "title": "menu",
                "children": ["folderCCCCCC"],
            }),
            json!({
                "id": "folderCCCCCC",
                "type": "folder",
                "parentid": "menu",
                "parentName": "menu",
                "dateAdded": 0,
                "title": "A",
                "children": ["bookmarkDDDD", "folderEEEEEE"],
            }),
            json!({
                "id": "bookmarkDDDD",
                "type": "bookmark",
                "parentid": "folderCCCCCC",
                "parentName": "C",
                "dateAdded": 0,
                "title": "D",
                "bmkUri": "http://example.com/d",
            }),
            json!({
                "id": "folderEEEEEE",
                "type": "folder",
                "parentid": "folderCCCCCC",
                "parentName": "C",
                "dateAdded": 0,
                "title": "E",
                "children": ["bookmarkFFFF"],
            }),
            json!({
                "id": "bookmarkFFFF",
                "type": "bookmark",
                "parentid": "folderEEEEEE",
                "parentName": "E",
                "dateAdded": 0,
                "title": "F",
                "bmkUri": "http://example.com/f",
            }),
        ];

        let interrupt_scope = syncer.begin_interrupt_scope();
        let store = BookmarksStore::new(&syncer, &interrupt_scope);

        let mut incoming = IncomingChangeset::new(store.collection_name(), ServerTimestamp(0));
        for record in records {
            let payload = Payload::from_json(record).unwrap();
            incoming.changes.push((payload, ServerTimestamp(0)));
        }

        let outgoing = store
            .apply_incoming(vec![incoming], &mut telemetry::Engine::new("bookmarks"))
            .expect("Should apply incoming records");
        let mut outgoing_ids = outgoing
            .changes
            .iter()
            .map(|p| p.id.clone())
            .collect::<Vec<_>>();
        outgoing_ids.sort();
        assert_eq!(outgoing_ids, &["menu", "mobile", "toolbar", "unfiled"],);

        store
            .sync_finished(ServerTimestamp(0), outgoing_ids)
            .expect("Should push synced changes back to the store");

        store.wipe().expect("Should wipe the store");

        // Wiping the store should delete all items except for the roots.
        assert_local_json_tree(
            &writer,
            &BookmarkRootGuid::Root.as_guid(),
            json!({
                "guid": &BookmarkRootGuid::Root.as_guid(),
                "children": [
                    {
                        "guid": &BookmarkRootGuid::Menu.as_guid(),
                        "children": [],
                    },
                    {
                        "guid": &BookmarkRootGuid::Toolbar.as_guid(),
                        "children": [],
                    },
                    {
                        "guid": &BookmarkRootGuid::Unfiled.as_guid(),
                        "children": [],
                    },
                    {
                        "guid": &BookmarkRootGuid::Mobile.as_guid(),
                        "children": [],
                    },
                ],
            }),
        );

        // Now pretend that F changed remotely between the time we called `wipe`
        // and the next sync.
        let record_for_f = json!({
            "id": "bookmarkFFFF",
            "type": "bookmark",
            "parentid": "folderEEEEEE",
            "parentName": "E",
            "dateAdded": 0,
            "title": "F (remote)",
            "bmkUri": "http://example.com/f-remote",
        });

        let mut incoming = IncomingChangeset::new(store.collection_name(), ServerTimestamp(1000));
        incoming.changes.push((
            Payload::from_json(record_for_f).unwrap(),
            ServerTimestamp(1000),
        ));

        let outgoing = store
            .apply_incoming(vec![incoming], &mut telemetry::Engine::new("bookmarks"))
            .expect("Should apply F and stage tombstones for A-E");
        let (outgoing_tombstones, outgoing_records): (Vec<_>, Vec<_>) =
            outgoing.changes.iter().partition(|record| record.deleted);
        let mut outgoing_record_ids = outgoing_records
            .into_iter()
            .map(|p| p.id.as_str())
            .collect::<Vec<_>>();
        outgoing_record_ids.sort();
        assert_eq!(
            outgoing_record_ids,
            &["bookmarkFFFF", "menu", "mobile", "toolbar", "unfiled"],
        );
        let mut outgoing_tombstone_ids = outgoing_tombstones
            .into_iter()
            .map(|p| p.id.clone())
            .collect::<Vec<_>>();
        outgoing_tombstone_ids.sort();
        assert_eq!(
            outgoing_tombstone_ids,
            &[
                "bookmarkBBBB",
                "bookmarkDDDD",
                "folderAAAAAA",
                "folderCCCCCC",
                "folderEEEEEE"
            ]
        );

        // F should move to the closest surviving ancestor, which, in this case,
        // is the menu.
        assert_local_json_tree(
            &writer,
            &BookmarkRootGuid::Root.as_guid(),
            json!({
                "guid": &BookmarkRootGuid::Root.as_guid(),
                "children": [
                    {
                        "guid": &BookmarkRootGuid::Menu.as_guid(),
                        "children": [
                            {
                                "guid": "bookmarkFFFF",
                                "title": "F (remote)",
                                "url": "http://example.com/f-remote",
                            },
                        ],
                    },
                    {
                        "guid": &BookmarkRootGuid::Toolbar.as_guid(),
                        "children": [],
                    },
                    {
                        "guid": &BookmarkRootGuid::Unfiled.as_guid(),
                        "children": [],
                    },
                    {
                        "guid": &BookmarkRootGuid::Mobile.as_guid(),
                        "children": [],
                    },
                ],
            }),
        );

        Ok(())
    }

    #[test]
    fn test_reset() -> result::Result<(), failure::Error> {
        let api = new_mem_api();
        let writer = api.open_connection(ConnectionType::ReadWrite)?;

        insert_local_json_tree(
            &writer,
            json!({
                "guid": &BookmarkRootGuid::Menu.as_guid(),
                "children": [
                    {
                        "guid": "bookmark2___",
                        "title": "2",
                        "url": "http://example.com/2",
                    }
                ],
            }),
        );

        {
            // scope to kill our sync connection.
            let syncer = api.open_sync_connection()?;
            let interrupt_scope = syncer.begin_interrupt_scope();
            let store = BookmarksStore::new(&syncer, &interrupt_scope);

            assert_eq!(store.get_sync_assoc()?, StoreSyncAssociation::Disconnected);

            let incoming = IncomingChangeset::new(store.collection_name(), ServerTimestamp(1_000));
            let outgoing =
                store.apply_incoming(vec![incoming], &mut telemetry::Engine::new("bookmarks"))?;
            let synced_ids: Vec<Guid> = outgoing.changes.iter().map(|c| c.id.clone()).collect();
            assert_eq!(synced_ids.len(), 5, "should be 4 roots + 1 outgoing item");
            store.sync_finished(ServerTimestamp(2_000), synced_ids)?;

            // now reset
            store.reset(&StoreSyncAssociation::Connected(CollSyncIds {
                global: Guid::random(),
                coll: Guid::random(),
            }))?;
        }
        // do it all again - after the reset we should get the same results.
        {
            let syncer = api.open_sync_connection()?;
            let interrupt_scope = syncer.begin_interrupt_scope();
            let store = BookmarksStore::new(&syncer, &interrupt_scope);

            let incoming = IncomingChangeset::new(store.collection_name(), ServerTimestamp(1_000));
            let outgoing =
                store.apply_incoming(vec![incoming], &mut telemetry::Engine::new("bookmarks"))?;
            let synced_ids: Vec<Guid> = outgoing.changes.iter().map(|c| c.id.clone()).collect();
            assert_eq!(synced_ids.len(), 5, "should be 4 roots + 1 outgoing item");
            store.sync_finished(ServerTimestamp(2_000), synced_ids)?;
        }

        Ok(())
    }

    #[test]
    fn test_dedupe_local_newer() -> result::Result<(), failure::Error> {
        let _ = env_logger::try_init();

        let api = new_mem_api();
        let writer = api.open_connection(ConnectionType::ReadWrite)?;
        let syncer = api.open_sync_connection()?;

        let local_modified = Timestamp::now();
        let remote_modified = local_modified.as_millis() as f64 / 1000f64 - 5f64;

        // Start with merged items.
        apply_incoming(
            &syncer,
            ServerTimestamp::from_float_seconds(remote_modified),
            json!([{
                "id": "menu",
                "type": "folder",
                "parentid": "places",
                "parentName": "",
                "title": "menu",
                "children": ["bookmarkAAA5"],
                "modified": remote_modified,
            }, {
                "id": "bookmarkAAA5",
                "type": "bookmark",
                "parentid": "menu",
                "parentName": "menu",
                "title": "A",
                "bmkUri": "http://example.com/a",
                "modified": remote_modified,
            }]),
        );

        // Add newer local dupes.
        insert_local_json_tree(
            &writer,
            json!({
                "guid": &BookmarkRootGuid::Menu.as_guid(),
                "children": [{
                    "guid": "bookmarkAAA1",
                    "title": "A",
                    "url": "http://example.com/a",
                    "date_added": local_modified,
                    "last_modified": local_modified,
                }, {
                    "guid": "bookmarkAAA2",
                    "title": "A",
                    "url": "http://example.com/a",
                    "date_added": local_modified,
                    "last_modified": local_modified,
                }, {
                    "guid": "bookmarkAAA3",
                    "title": "A",
                    "url": "http://example.com/a",
                    "date_added": local_modified,
                    "last_modified": local_modified,
                }],
            }),
        );

        // Add older remote dupes.
        apply_incoming(
            &syncer,
            ServerTimestamp(local_modified.as_millis() as i64),
            json!([{
                "id": "menu",
                "type": "folder",
                "parentid": "places",
                "parentName": "",
                "title": "menu",
                "children": ["bookmarkAAAA", "bookmarkAAA4", "bookmarkAAA5"],
            }, {
                "id": "bookmarkAAAA",
                "type": "bookmark",
                "parentid": "menu",
                "parentName": "menu",
                "title": "A",
                "bmkUri": "http://example.com/a",
                "modified": remote_modified,
            }, {
                "id": "bookmarkAAA4",
                "type": "bookmark",
                "parentid": "menu",
                "parentName": "menu",
                "title": "A",
                "bmkUri": "http://example.com/a",
                "modified": remote_modified,
            }]),
        );

        assert_local_json_tree(
            &writer,
            &BookmarkRootGuid::Menu.as_guid(),
            json!({
                "guid": &BookmarkRootGuid::Menu.as_guid(),
                "children": [{
                    "guid": "bookmarkAAAA",
                    "title": "A",
                    "url": "http://example.com/a",
                }, {
                    "guid": "bookmarkAAA4",
                    "title": "A",
                    "url": "http://example.com/a",
                }, {
                    "guid": "bookmarkAAA5",
                    "title": "A",
                    "url": "http://example.com/a",
                }, {
                    "guid": "bookmarkAAA3",
                    "title": "A",
                    "url": "http://example.com/a",
                }],
            }),
        );

        Ok(())
    }

    #[test]
    fn test_deduping_remote_newer() -> result::Result<(), failure::Error> {
        let _ = env_logger::try_init();

        let api = new_mem_api();
        let writer = api.open_connection(ConnectionType::ReadWrite)?;
        let syncer = api.open_sync_connection()?;

        let local_modified = Timestamp::from(Timestamp::now().as_millis() - 5000);
        let remote_modified = local_modified.as_millis() as f64 / 1000f64;

        // Start with merged items.
        apply_incoming(
            &syncer,
            ServerTimestamp::from_float_seconds(remote_modified),
            json!([{
                "id": "menu",
                "type": "folder",
                "parentid": "places",
                "parentName": "",
                "title": "menu",
                "children": ["folderAAAAAA"],
                "modified": remote_modified,
            }, {
                // Shouldn't dedupe to `folderA11111` because it's been applied.
                "id": "folderAAAAAA",
                "type": "folder",
                "parentid": "menu",
                "parentName": "menu",
                "title": "A",
                "children": ["bookmarkGGGG"],
                "modified": remote_modified,
            }, {
                // Shouldn't dedupe to `bookmarkG111`.
                "id": "bookmarkGGGG",
                "type": "bookmark",
                "parentid": "folderAAAAAA",
                "parentName": "A",
                "title": "G",
                "bmkUri": "http://example.com/g",
                "modified": remote_modified,
            }]),
        );

        // Add older local dupes.
        insert_local_json_tree(
            &writer,
            json!({
                "guid": "folderAAAAAA",
                "children": [{
                    // Not a candidate for `bookmarkH111` because we didn't dupe `folderAAAAAA`.
                    "guid": "bookmarkHHHH",
                    "title": "H",
                    "url": "http://example.com/h",
                    "date_added": local_modified,
                    "last_modified": local_modified,
                }]
            }),
        );
        insert_local_json_tree(
            &writer,
            json!({
                "guid": &BookmarkRootGuid::Menu.as_guid(),
                "children": [{
                    // Should dupe to `folderB11111`.
                    "guid": "folderBBBBBB",
                    "type": BookmarkType::Folder as u8,
                    "title": "B",
                    "date_added": local_modified,
                    "last_modified": local_modified,
                    "children": [{
                        // Should dupe to `bookmarkC222`.
                        "guid": "bookmarkC111",
                        "title": "C",
                        "url": "http://example.com/c",
                        "date_added": local_modified,
                        "last_modified": local_modified,
                    }, {
                        // Should dupe to `separatorF11` because the positions are the same.
                        "guid": "separatorFFF",
                        "type": BookmarkType::Separator as u8,
                        "date_added": local_modified,
                        "last_modified": local_modified,
                    }],
                }, {
                    // Shouldn't dupe to `separatorE11`, because the positions are different.
                    "guid": "separatorEEE",
                    "type": BookmarkType::Separator as u8,
                    "date_added": local_modified,
                    "last_modified": local_modified,
                }, {
                    // Shouldn't dupe to `bookmarkC222` because the parents are different.
                    "guid": "bookmarkCCCC",
                    "title": "C",
                    "url": "http://example.com/c",
                    "date_added": local_modified,
                    "last_modified": local_modified,
                }, {
                    // Should dupe to `queryD111111`.
                    "guid": "queryDDDDDDD",
                    "title": "Most Visited",
                    "url": "place:maxResults=10&sort=8",
                    "date_added": local_modified,
                    "last_modified": local_modified,
                }],
            }),
        );

        // Add newer remote items.
        apply_incoming(
            &syncer,
            ServerTimestamp::from_float_seconds(remote_modified),
            json!([{
                "id": "menu",
                "type": "folder",
                "parentid": "places",
                "parentName": "",
                "title": "menu",
                "children": ["folderAAAAAA", "folderB11111", "folderA11111", "separatorE11", "queryD111111"],
                "dateAdded": local_modified.as_millis(),
                "modified": remote_modified + 5f64,
            }, {
                "id": "folderB11111",
                "type": "folder",
                "parentid": "menu",
                "parentName": "menu",
                "title": "B",
                "children": ["bookmarkC222", "separatorF11"],
                "dateAdded": local_modified.as_millis(),
                "modified": remote_modified + 5f64,
            }, {
                "id": "bookmarkC222",
                "type": "bookmark",
                "parentid": "folderB11111",
                "parentName": "B",
                "title": "C",
                "bmkUri": "http://example.com/c",
                "dateAdded": local_modified.as_millis(),
                "modified": remote_modified + 5f64,
            }, {
                "id": "separatorF11",
                "type": "separator",
                "parentid": "folderB11111",
                "parentName": "B",
                "dateAdded": local_modified.as_millis(),
                "modified": remote_modified + 5f64,
            }, {
                "id": "folderA11111",
                "type": "folder",
                "parentid": "menu",
                "parentName": "menu",
                "title": "A",
                "children": ["bookmarkG111"],
                "dateAdded": local_modified.as_millis(),
                "modified": remote_modified + 5f64,
            }, {
                "id": "bookmarkG111",
                "type": "bookmark",
                "parentid": "folderA11111",
                "parentName": "A",
                "title": "G",
                "bmkUri": "http://example.com/g",
                "dateAdded": local_modified.as_millis(),
                "modified": remote_modified + 5f64,
            }, {
                "id": "separatorE11",
                "type": "separator",
                "parentid": "folderB11111",
                "parentName": "B",
                "dateAdded": local_modified.as_millis(),
                "modified": remote_modified + 5f64,
            }, {
                "id": "queryD111111",
                "type": "query",
                "parentid": "menu",
                "parentName": "menu",
                "title": "Most Visited",
                "bmkUri": "place:maxResults=10&sort=8",
                "dateAdded": local_modified.as_millis(),
                "modified": remote_modified + 5f64,
            }]),
        );

        assert_local_json_tree(
            &writer,
            &BookmarkRootGuid::Menu.as_guid(),
            json!({
                "guid": &BookmarkRootGuid::Menu.as_guid(),
                "children": [{
                    "guid": "folderAAAAAA",
                    "children": [{
                        "guid": "bookmarkGGGG",
                        "title": "G",
                        "url": "http://example.com/g",
                    }, {
                        "guid": "bookmarkHHHH",
                        "title": "H",
                        "url": "http://example.com/h",
                    }]
                }, {
                    "guid": "folderB11111",
                    "children": [{
                        "guid": "bookmarkC222",
                        "title": "C",
                        "url": "http://example.com/c",
                    }, {
                        "guid": "separatorF11",
                        "type": BookmarkType::Separator as u8,
                    }],
                }, {
                    "guid": "folderA11111",
                    "children": [{
                        "guid": "bookmarkG111",
                        "title": "G",
                        "url": "http://example.com/g",
                    }]
                }, {
                    "guid": "separatorE11",
                    "type": BookmarkType::Separator as u8,
                }, {
                    "guid": "queryD111111",
                    "title": "Most Visited",
                    "url": "place:maxResults=10&sort=8",
                }, {
                    "guid": "separatorEEE",
                    "type": BookmarkType::Separator as u8,
                }, {
                    "guid": "bookmarkCCCC",
                    "title": "C",
                    "url": "http://example.com/c",
                }],
            }),
        );

        Ok(())
    }
}
