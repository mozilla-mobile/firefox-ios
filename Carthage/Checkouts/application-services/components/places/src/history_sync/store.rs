/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::api::places_api::{ConnectionType, GLOBAL_STATE_META_KEY};
use crate::db::PlacesDb;
use crate::error::*;
use crate::storage::history::{
    delete_everything,
    history_sync::{reset, reset_meta},
};
use rusqlite::types::{FromSql, ToSql};
use rusqlite::Connection;
use sql_support::SqlInterruptScope;
use std::ops::Deref;
use std::result;
use sync15::telemetry;
use sync15::{
    extract_v1_state, CollSyncIds, CollectionRequest, IncomingChangeset, OutgoingChangeset,
    ServerTimestamp, Store, StoreSyncAssociation,
};
use sync_guid::Guid;

use super::plan::{apply_plan, finish_plan};
use super::MAX_INCOMING_PLACES;

pub const LAST_SYNC_META_KEY: &str = "history_last_sync_time";
// Note that all engines in this crate should use a *different* meta key
// for the global sync ID, because engines are reset individually.
pub const GLOBAL_SYNCID_META_KEY: &str = "history_global_sync_id";
pub const COLLECTION_SYNCID_META_KEY: &str = "history_sync_id";

// A HistoryStore is short-lived and constructed each sync by something which
// owns the connection and ClientInfo.
pub struct HistoryStore<'a> {
    pub db: &'a PlacesDb,
    interruptee: &'a SqlInterruptScope,
}

impl<'a> HistoryStore<'a> {
    pub fn new(db: &'a PlacesDb, interruptee: &'a SqlInterruptScope) -> Self {
        assert_eq!(db.conn_type(), ConnectionType::Sync);
        Self { db, interruptee }
    }

    fn put_meta(&self, key: &str, value: &dyn ToSql) -> Result<()> {
        crate::storage::put_meta(self.db, key, value)
    }

    fn get_meta<T: FromSql>(&self, key: &str) -> Result<Option<T>> {
        crate::storage::get_meta(self.db, key)
    }

    fn do_apply_incoming(
        &self,
        inbound: IncomingChangeset,
        telem: &mut telemetry::Engine,
    ) -> Result<OutgoingChangeset> {
        let timestamp = inbound.timestamp;
        let outgoing = {
            let mut incoming_telemetry = telemetry::EngineIncoming::new();
            let result = apply_plan(&self.db, inbound, &mut incoming_telemetry, self.interruptee);
            telem.incoming(incoming_telemetry);
            result
        }?;
        // write the timestamp now, so if we are interrupted creating outgoing
        // changesets we don't need to re-reconcile what we just did.
        self.put_meta(LAST_SYNC_META_KEY, &(timestamp.as_millis() as i64))?;
        Ok(outgoing)
    }

    fn do_sync_finished(
        &self,
        new_timestamp: ServerTimestamp,
        records_synced: Vec<Guid>,
    ) -> Result<()> {
        log::info!(
            "sync completed after uploading {} records",
            records_synced.len()
        );
        finish_plan(&self.db)?;

        // write timestamp to reflect what we just wrote.
        self.put_meta(LAST_SYNC_META_KEY, &(new_timestamp.as_millis() as i64))?;

        self.db.pragma_update(None, "wal_checkpoint", &"PASSIVE")?;

        Ok(())
    }

    pub(crate) fn do_reset(&self, assoc: &StoreSyncAssociation) -> Result<()> {
        match assoc {
            StoreSyncAssociation::Disconnected => {
                reset(self.db)?;
            }
            StoreSyncAssociation::Connected(ids) => {
                let tx = self.db.begin_transaction()?;
                reset_meta(self.db)?;
                self.put_meta(GLOBAL_SYNCID_META_KEY, &ids.global)?;
                self.put_meta(COLLECTION_SYNCID_META_KEY, &ids.coll)?;
                tx.commit()?;
            }
        }
        Ok(())
    }

    /// A utility we can kill by the end of 2019 ;) Or even mid-2019?
    /// Note that this has no `self` - it just takes a connection. This is to
    /// ease the migration process, because this needs to be executed before
    /// bookmarks sync, otherwise the shared, persisted global state may be
    /// written by bookmarks before we've had a chance to migrate `declined`
    /// over.
    pub fn migrate_v1_global_state(db: &PlacesDb) -> Result<()> {
        if let Some(old_state) = crate::storage::get_meta(db, "history_global_state")? {
            log::info!("there's old global state - migrating");
            let tx = db.begin_transaction()?;
            let (new_sync_ids, new_global_state) = extract_v1_state(old_state, "history");
            if let Some(sync_ids) = new_sync_ids {
                crate::storage::put_meta(db, GLOBAL_SYNCID_META_KEY, &sync_ids.global)?;
                crate::storage::put_meta(db, COLLECTION_SYNCID_META_KEY, &sync_ids.coll)?;
                log::info!("migrated the sync IDs");
            }
            if let Some(new_global_state) = new_global_state {
                // The global state is truly global, but both "history" and "places"
                // are going to write it - which is why it's important this
                // function is run before bookmarks is synced.
                crate::storage::put_meta(db, GLOBAL_STATE_META_KEY, &new_global_state)?;
                log::info!("migrated the global state");
            }
            crate::storage::delete_meta(db, "history_global_state")?;
            tx.commit()?;
        }
        Ok(())
    }
}

impl<'a> Deref for HistoryStore<'a> {
    type Target = Connection;
    #[inline]
    fn deref(&self) -> &Connection {
        &self.db
    }
}

impl<'a> Store for HistoryStore<'a> {
    fn collection_name(&self) -> std::borrow::Cow<'static, str> {
        "history".into()
    }

    fn apply_incoming(
        &self,
        inbound: Vec<IncomingChangeset>,
        telem: &mut telemetry::Engine,
    ) -> result::Result<OutgoingChangeset, failure::Error> {
        assert_eq!(inbound.len(), 1, "history only requests one item");
        let inbound = inbound.into_iter().next().unwrap();
        Ok(self.do_apply_incoming(inbound, telem)?)
    }

    fn sync_finished(
        &self,
        new_timestamp: ServerTimestamp,
        records_synced: Vec<Guid>,
    ) -> result::Result<(), failure::Error> {
        self.do_sync_finished(new_timestamp, records_synced)?;
        Ok(())
    }

    fn get_collection_requests(
        &self,
        server_timestamp: ServerTimestamp,
    ) -> result::Result<Vec<CollectionRequest>, failure::Error> {
        let since = ServerTimestamp(
            self.get_meta::<i64>(LAST_SYNC_META_KEY)?
                .unwrap_or_default(),
        );
        Ok(if since == server_timestamp {
            vec![]
        } else {
            vec![CollectionRequest::new("history")
                .full()
                .newer_than(since)
                .limit(MAX_INCOMING_PLACES)]
        })
    }

    fn get_sync_assoc(&self) -> result::Result<StoreSyncAssociation, failure::Error> {
        let global = self.get_meta(GLOBAL_SYNCID_META_KEY)?;
        let coll = self.get_meta(COLLECTION_SYNCID_META_KEY)?;
        Ok(if let (Some(global), Some(coll)) = (global, coll) {
            StoreSyncAssociation::Connected(CollSyncIds { global, coll })
        } else {
            StoreSyncAssociation::Disconnected
        })
    }

    fn reset(&self, assoc: &StoreSyncAssociation) -> result::Result<(), failure::Error> {
        self.do_reset(assoc)?;
        Ok(())
    }

    fn wipe(&self) -> result::Result<(), failure::Error> {
        delete_everything(&self.db)?;
        Ok(())
    }
}
