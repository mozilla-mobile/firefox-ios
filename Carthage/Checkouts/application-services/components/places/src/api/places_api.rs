/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::bookmark_sync::store::BookmarksStore;
use crate::db::db::PlacesDb;
use crate::error::*;
use crate::history_sync::store::HistoryStore;
use crate::storage::{self, delete_meta, get_meta, put_meta};
use crate::util::normalize_path;
use lazy_static::lazy_static;
use rusqlite::OpenFlags;
use sql_support::SqlInterruptHandle;
use std::cell::Cell;
use std::collections::HashMap;
use std::fs;
use std::mem;
use std::path::{Path, PathBuf};
use std::sync::{
    atomic::{AtomicBool, AtomicUsize, Ordering},
    Arc, Mutex, Weak,
};
use sync15::{sync_multiple, telemetry, MemoryCachedState, SyncResult};

// Not clear if this should be here, but this is the "global sync state"
// which is persisted to disk and reused for all engines.
// Note that this is only ever round-tripped, and never changed by, or impacted
// by a store or collection, so it's safe to storage globally rather than
// per collection.
pub const GLOBAL_STATE_META_KEY: &str = "global_sync_state_v2";

#[repr(u8)]
#[derive(Debug, Copy, Clone, PartialEq)]
pub enum ConnectionType {
    ReadOnly = 1,
    ReadWrite = 2,
    Sync = 3,
}

impl ConnectionType {
    pub fn from_primitive(p: u8) -> Option<Self> {
        match p {
            1 => Some(ConnectionType::ReadOnly),
            2 => Some(ConnectionType::ReadWrite),
            3 => Some(ConnectionType::Sync),
            _ => None,
        }
    }
}

impl ConnectionType {
    pub fn rusqlite_flags(self) -> OpenFlags {
        let common_flags = OpenFlags::SQLITE_OPEN_NO_MUTEX | OpenFlags::SQLITE_OPEN_URI;
        match self {
            ConnectionType::ReadOnly => common_flags | OpenFlags::SQLITE_OPEN_READ_ONLY,
            ConnectionType::ReadWrite => {
                common_flags | OpenFlags::SQLITE_OPEN_CREATE | OpenFlags::SQLITE_OPEN_READ_WRITE
            }
            ConnectionType::Sync => common_flags | OpenFlags::SQLITE_OPEN_READ_WRITE,
        }
    }
}

// We only allow a single PlacesApi per filename.
lazy_static! {
    static ref APIS: Mutex<HashMap<PathBuf, Weak<PlacesApi>>> = Mutex::new(HashMap::new());
}

static ID_COUNTER: AtomicUsize = AtomicUsize::new(0);

pub struct SyncState {
    pub mem_cached_state: Cell<MemoryCachedState>,
    pub disk_cached_state: Cell<Option<String>>,
}

/// The entry-point to the places API. This object gives access to database
/// connections and other helpers. It enforces that only 1 write connection
/// can exist to the database at once.
pub struct PlacesApi {
    db_name: PathBuf,
    write_connection: Mutex<Option<PlacesDb>>,
    sync_state: Mutex<Option<SyncState>>,
    coop_tx_lock: Arc<Mutex<()>>,
    sync_conn_active: AtomicBool,
    id: usize,
}
impl PlacesApi {
    /// Create a new, or fetch an already open, PlacesApi backed by a file on disk.
    pub fn new(db_name: impl AsRef<Path>) -> Result<Arc<Self>> {
        let db_name = normalize_path(db_name)?;
        Self::new_or_existing(db_name)
    }

    /// Create a new, or fetch an already open, memory-based PlacesApi. You must
    /// provide a name, but you are still able to have a single writer and many
    ///  reader connections to the same memory DB open.
    pub fn new_memory(db_name: &str) -> Result<Arc<Self>> {
        let name = PathBuf::from(format!("file:{}?mode=memory&cache=shared", db_name));
        Self::new_or_existing(name)
    }
    fn new_or_existing_into(
        target: &mut HashMap<PathBuf, Weak<PlacesApi>>,
        db_name: PathBuf,
        delete_on_fail: bool,
    ) -> Result<Arc<Self>> {
        let id = ID_COUNTER.fetch_add(1, Ordering::SeqCst);
        match target.get(&db_name).and_then(Weak::upgrade) {
            Some(existing) => Ok(existing),
            None => {
                // We always create a new read-write connection for an initial open so
                // we can create the schema and/or do version upgrades.
                let coop_tx_lock = Arc::new(Mutex::new(()));
                match PlacesDb::open(
                    &db_name,
                    ConnectionType::ReadWrite,
                    id,
                    coop_tx_lock.clone(),
                ) {
                    Ok(connection) => {
                        let new = PlacesApi {
                            db_name: db_name.clone(),
                            write_connection: Mutex::new(Some(connection)),
                            sync_state: Mutex::new(None),
                            sync_conn_active: AtomicBool::new(false),
                            id,
                            coop_tx_lock,
                        };
                        let arc = Arc::new(new);
                        target.insert(db_name, Arc::downgrade(&arc));
                        Ok(arc)
                    }
                    Err(e) => {
                        if !delete_on_fail {
                            return Err(e);
                        }
                        if let ErrorKind::DatabaseUpgradeError = e.kind() {
                            fs::remove_file(&db_name)?;
                            Self::new_or_existing_into(target, db_name, false)
                        } else {
                            Err(e)
                        }
                    }
                }
            }
        }
    }

    fn new_or_existing(db_name: PathBuf) -> Result<Arc<Self>> {
        let mut guard = APIS.lock().unwrap();
        Self::new_or_existing_into(&mut guard, db_name, true)
    }

    /// Open a connection to the database.
    pub fn open_connection(&self, conn_type: ConnectionType) -> Result<PlacesDb> {
        match conn_type {
            ConnectionType::ReadOnly => {
                // make a new one - we can have as many of these as we want.
                PlacesDb::open(
                    self.db_name.clone(),
                    ConnectionType::ReadOnly,
                    self.id,
                    self.coop_tx_lock.clone(),
                )
            }
            ConnectionType::ReadWrite => {
                // We only allow one of these.
                let mut guard = self.write_connection.lock().unwrap();
                match mem::replace(&mut *guard, None) {
                    None => Err(ErrorKind::ConnectionAlreadyOpen.into()),
                    Some(db) => Ok(db),
                }
            }
            ConnectionType::Sync => {
                panic!("Use `open_sync_connection` to open a sync connection");
            }
        }
    }

    pub fn open_sync_connection(&self) -> Result<SyncConn<'_>> {
        let prev_value = self
            .sync_conn_active
            .compare_and_swap(false, true, Ordering::SeqCst);
        if prev_value {
            Err(ErrorKind::ConnectionAlreadyOpen.into())
        } else {
            let db = PlacesDb::open(
                self.db_name.clone(),
                ConnectionType::Sync,
                self.id,
                self.coop_tx_lock.clone(),
            )?;
            Ok(SyncConn {
                db,
                flag: &self.sync_conn_active,
            })
        }
    }

    /// Close a connection to the database. If the connection is the write
    /// connection, you can re-fetch it using open_connection.
    pub fn close_connection(&self, connection: PlacesDb) -> Result<()> {
        if connection.api_id() != self.id {
            return Err(ErrorKind::WrongApiForClose.into());
        }
        if connection.conn_type() == ConnectionType::ReadWrite {
            // We only allow one of these.
            let mut guard = self.write_connection.lock().unwrap();
            assert!((*guard).is_none());
            *guard = Some(connection);
        }
        Ok(())
    }

    fn get_disk_persisted_state(&self, conn: &PlacesDb) -> Result<Option<String>> {
        Ok(get_meta::<String>(&conn, GLOBAL_STATE_META_KEY)?)
    }

    fn set_disk_persisted_state(&self, conn: &PlacesDb, state: &Option<String>) -> Result<()> {
        match state {
            Some(ref s) => put_meta(&conn, GLOBAL_STATE_META_KEY, s),
            None => delete_meta(&conn, GLOBAL_STATE_META_KEY),
        }
    }

    // NOTE: These should be deprecated as soon as possible - that will be once
    // all consumers have been updated to use the .sync() method below, and/or
    // we have implemented the sync manager and migrated consumers to that.
    pub fn sync_history(
        &self,
        client_init: &sync15::Sync15StorageClientInit,
        key_bundle: &sync15::KeyBundle,
    ) -> Result<telemetry::SyncTelemetryPing> {
        self.do_sync_one(
            "history",
            move |conn, mem_cached_state, disk_cached_state| {
                let interruptee = conn.begin_interrupt_scope();
                let store = HistoryStore::new(&conn, &interruptee);
                sync_multiple(
                    &[&store],
                    disk_cached_state,
                    mem_cached_state,
                    client_init,
                    key_bundle,
                    &interruptee,
                    None,
                )
            },
        )
    }

    pub fn sync_bookmarks(
        &self,
        client_init: &sync15::Sync15StorageClientInit,
        key_bundle: &sync15::KeyBundle,
    ) -> Result<telemetry::SyncTelemetryPing> {
        self.do_sync_one(
            "bookmarks",
            move |conn, mem_cached_state, disk_cached_state| {
                let interruptee = conn.begin_interrupt_scope();
                let store = BookmarksStore::new(&conn, &interruptee);
                sync_multiple(
                    &[&store],
                    disk_cached_state,
                    mem_cached_state,
                    client_init,
                    key_bundle,
                    &interruptee,
                    None,
                )
            },
        )
    }

    pub fn do_sync_one<F>(
        &self,
        name: &'static str,
        syncer: F,
    ) -> Result<telemetry::SyncTelemetryPing>
    where
        F: FnOnce(&SyncConn<'_>, &mut MemoryCachedState, &mut Option<String>) -> SyncResult,
    {
        let mut guard = self.sync_state.lock().unwrap();
        let conn = self.open_sync_connection()?;
        if guard.is_none() {
            *guard = Some(SyncState {
                mem_cached_state: Cell::default(),
                disk_cached_state: Cell::new(self.get_disk_persisted_state(&conn)?),
            });
        }

        let sync_state = guard.as_ref().unwrap();
        // Note that this *must* be called before either history or bookmarks are
        // synced, to ensure the shared global state is correct.
        HistoryStore::migrate_v1_global_state(&conn)?;

        let mut mem_cached_state = sync_state.mem_cached_state.take();
        let mut disk_cached_state = sync_state.disk_cached_state.take();
        let mut result = syncer(&conn, &mut mem_cached_state, &mut disk_cached_state);
        // even on failure we set the persisted state - sync itself takes care
        // to ensure this has been None'd out if necessary.
        self.set_disk_persisted_state(&conn, &disk_cached_state)?;
        sync_state.mem_cached_state.replace(mem_cached_state);
        sync_state.disk_cached_state.replace(disk_cached_state);

        // for b/w compat reasons, we do some dances with the result.
        if let Err(e) = result.result {
            return Err(e.into());
        }
        match result.engine_results.remove(name) {
            None | Some(Ok(())) => Ok(result.telemetry),
            Some(Err(e)) => Err(e.into()),
        }
    }

    // This is the new sync API until the sync manager lands. It's currently
    // not wired up via the FFI - it's possible we'll do declined engines too
    // before we do.
    // Note we've made a policy decision about the return value - even though
    // it is Result<SyncResult>, we will only return an Err() if there's a
    // fatal error that prevents us starting a sync, such as failure to open
    // the DB. Any errors that happen *after* sync must not escape - ie, once
    // we have a SyncResult, we must return it.
    pub fn sync(
        &self,
        client_init: &sync15::Sync15StorageClientInit,
        key_bundle: &sync15::KeyBundle,
    ) -> Result<SyncResult> {
        let mut guard = self.sync_state.lock().unwrap();
        let conn = self.open_sync_connection()?;
        if guard.is_none() {
            *guard = Some(SyncState {
                mem_cached_state: Cell::default(),
                disk_cached_state: Cell::new(self.get_disk_persisted_state(&conn)?),
            });
        }

        let sync_state = guard.as_ref().unwrap();
        // Note that counter-intuitively, this must be called before we do a
        // bookmark sync too, to ensure the shared global state is correct.
        HistoryStore::migrate_v1_global_state(&conn)?;

        let interruptee = conn.begin_interrupt_scope();
        let bm_store = BookmarksStore::new(&conn, &interruptee);
        let history_store = HistoryStore::new(&conn, &interruptee);
        let mut mem_cached_state = sync_state.mem_cached_state.take();
        let mut disk_cached_state = sync_state.disk_cached_state.take();

        // NOTE: After here we must never return Err()!
        let result = sync15::sync_multiple(
            &[&history_store, &bm_store],
            &mut disk_cached_state,
            &mut mem_cached_state,
            client_init,
            key_bundle,
            &interruptee,
            None,
        );
        // even on failure we set the persisted state - sync itself takes care
        // to ensure this has been None'd out if necessary.
        if let Err(e) = self.set_disk_persisted_state(&conn, &disk_cached_state) {
            log::error!("Failed to persist the sync state: {:?}", e);
        }
        sync_state.mem_cached_state.replace(mem_cached_state);
        sync_state.disk_cached_state.replace(disk_cached_state);

        Ok(result)
    }

    pub fn wipe_bookmarks(&self) -> Result<()> {
        // Take the lock to prevent syncing while we're doing this.
        let _guard = self.sync_state.lock().unwrap();
        let conn = self.open_sync_connection()?;

        // Somewhat ironically, we start by migrating from the legacy storage
        // format. We *are* just going to delete it anyway, but the code is
        // simpler if we can just reuse the existing path.
        HistoryStore::migrate_v1_global_state(&conn)?;

        storage::bookmarks::delete_everything(&conn)?;
        Ok(())
    }

    pub fn reset_bookmarks(&self) -> Result<()> {
        // Take the lock to prevent syncing while we're doing this.
        let _guard = self.sync_state.lock().unwrap();
        let conn = self.open_sync_connection()?;

        // Somewhat ironically, we start by migrating from the legacy storage
        // format. We *are* just going to delete it anyway, but the code is
        // simpler if we can just reuse the existing path.
        HistoryStore::migrate_v1_global_state(&conn)?;

        // We'd rather you didn't interrupt this, but it's a required arg for
        // BookmarksStore.
        let scope = conn.begin_interrupt_scope();
        let store = BookmarksStore::new(&conn, &scope);
        store.reset(&sync15::StoreSyncAssociation::Disconnected)?;

        Ok(())
    }

    pub fn wipe_history(&self) -> Result<()> {
        // Take the lock to prevent syncing while we're doing this.
        let _guard = self.sync_state.lock().unwrap();
        let conn = self.open_sync_connection()?;

        // Somewhat ironically, we start by migrating from the legacy storage
        // format. We *are* just going to delete it anyway, but the code is
        // simpler if we can just reuse the existing path.
        HistoryStore::migrate_v1_global_state(&conn)?;

        storage::history::delete_everything(&conn)?;
        Ok(())
    }

    pub fn reset_history(&self) -> Result<()> {
        // Take the lock to prevent syncing while we're doing this.
        let _guard = self.sync_state.lock().unwrap();
        let conn = self.open_sync_connection()?;

        // Somewhat ironically, we start by migrating from the legacy storage
        // format. We *are* just going to delete it anyway, but the code is
        // simpler if we can just reuse the existing path.
        HistoryStore::migrate_v1_global_state(&conn)?;

        // We'd rather you didn't interrupt this, but it's a required arg for
        // HistoryStore
        let scope = conn.begin_interrupt_scope();
        let store = HistoryStore::new(&conn, &scope);
        store.do_reset(&sync15::StoreSyncAssociation::Disconnected)
    }

    /// Get a new interrupt handle for the sync connection.
    pub fn new_sync_conn_interrupt_handle(&self) -> Result<SqlInterruptHandle> {
        // Probably not necessary to lock here, since this should only get
        // called in startup.
        let _guard = self.sync_state.lock().unwrap();
        let conn = self.open_sync_connection()?;
        Ok(conn.new_interrupt_handle())
    }
}

/// Wrapper around PlacesDb that automatically sets a flag (`sync_conn_active`)
/// to false when finished
pub struct SyncConn<'api> {
    db: PlacesDb,
    flag: &'api AtomicBool,
}

impl<'a> Drop for SyncConn<'a> {
    fn drop(&mut self) {
        self.flag.store(false, Ordering::SeqCst)
    }
}

impl<'a> std::ops::Deref for SyncConn<'a> {
    type Target = PlacesDb;
    fn deref(&self) -> &PlacesDb {
        &self.db
    }
}

#[cfg(test)]
pub mod test {
    use super::*;
    use std::sync::atomic::{AtomicUsize, Ordering};

    // A helper for our tests to get their own memory Api.
    static ATOMIC_COUNTER: AtomicUsize = AtomicUsize::new(0);

    pub fn new_mem_api() -> Arc<PlacesApi> {
        let counter = ATOMIC_COUNTER.fetch_add(1, Ordering::Relaxed);
        PlacesApi::new_memory(&format!("test-api-{}", counter)).expect("should get an API")
    }

    pub fn new_mem_connection() -> PlacesDb {
        new_mem_api()
            .open_connection(ConnectionType::ReadWrite)
            .expect("should get a connection")
    }

    pub struct MemConnections {
        pub read: PlacesDb,
        pub write: PlacesDb,
        pub api: Arc<PlacesApi>,
    }

    pub fn new_mem_connections() -> MemConnections {
        let api = new_mem_api();
        let read = api
            .open_connection(ConnectionType::ReadOnly)
            .expect("should get a read connection");
        let write = api
            .open_connection(ConnectionType::ReadWrite)
            .expect("should get a write connection");
        MemConnections { api, read, write }
    }
}

#[cfg(test)]
mod tests {
    use super::test::*;
    use super::*;
    use sql_support::ConnExt;

    #[test]
    fn test_multi_writers_fails() {
        let api = new_mem_api();
        let writer1 = api
            .open_connection(ConnectionType::ReadWrite)
            .expect("should get writer");
        api.open_connection(ConnectionType::ReadWrite)
            .expect_err("should fail to get second writer");
        // But we should be able to re-get it after closing it.
        api.close_connection(writer1)
            .expect("should be able to close");
        api.open_connection(ConnectionType::ReadWrite)
            .expect("should get a writer after closing the other");
    }

    #[test]
    fn test_shared_memory() {
        let api = new_mem_api();
        let writer = api
            .open_connection(ConnectionType::ReadWrite)
            .expect("should get writer");
        writer
            .execute_batch(
                "CREATE TABLE test_table (test_value INTEGER);
                              INSERT INTO test_table VALUES (999)",
            )
            .expect("should insert");
        let reader = api
            .open_connection(ConnectionType::ReadOnly)
            .expect("should get reader");
        let val = reader
            .query_one::<i64>("SELECT test_value FROM test_table")
            .expect("should get value");
        assert_eq!(val, 999);
    }

    #[test]
    fn test_reader_before_writer() {
        let api = new_mem_api();
        let reader = api
            .open_connection(ConnectionType::ReadOnly)
            .expect("should get reader");
        let writer = api
            .open_connection(ConnectionType::ReadWrite)
            .expect("should get writer");
        writer
            .execute_batch(
                "CREATE TABLE test_table (test_value INTEGER);
                              INSERT INTO test_table VALUES (999)",
            )
            .expect("should insert");
        let val = reader
            .query_one::<i64>("SELECT test_value FROM test_table")
            .expect("should get value");
        assert_eq!(val, 999);
    }

    #[test]
    fn test_wrong_writer_close() {
        let api = new_mem_api();
        // Grab this so `api` doesn't think it still has a writer.
        let _writer = api
            .open_connection(ConnectionType::ReadWrite)
            .expect("should get writer");

        let fake_api = new_mem_api();
        let fake_writer = fake_api
            .open_connection(ConnectionType::ReadWrite)
            .expect("should get writer 2");

        // No PartialEq on ErrorKind, so we abuse match.
        match api.close_connection(fake_writer).unwrap_err().kind() {
            &ErrorKind::WrongApiForClose => {}
            e => panic!("Expected error WrongApiForClose, got {:?}", e),
        }
    }

    #[test]
    fn test_valid_writer_close() {
        let api = new_mem_api();
        let writer = api
            .open_connection(ConnectionType::ReadWrite)
            .expect("should get writer");

        api.close_connection(writer)
            .expect("Should allow closing own connection");

        // Make sure we can open it again.
        assert!(api.open_connection(ConnectionType::ReadWrite).is_ok());
    }

    #[test]
    fn test_old_db_version() -> Result<()> {
        let dirname = tempfile::tempdir().unwrap();
        let db_name = dirname.path().join("temp.db");
        let id = {
            let api = PlacesApi::new(&db_name)?;
            let conn = api.open_connection(ConnectionType::ReadWrite)?;
            conn.execute_batch("PRAGMA user_version = 1;")?;
            api.close_connection(conn)?;
            api.id
        };
        let api2 = PlacesApi::new(&db_name)?;
        assert_ne!(id, api2.id);
        let conn = api2.open_connection(ConnectionType::ReadWrite)?;
        assert_ne!(1, conn.db.query_one::<i64>("PRAGMA user_version")?);
        Ok(())
    }
}
