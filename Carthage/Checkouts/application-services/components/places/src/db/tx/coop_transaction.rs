/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! This implements "cooperative transactions" for places. It relies on our
//! decision to have exactly 1 general purpose "writer" connection and exactly
//! one "sync writer" - ie, exactly 2 write connections.
//!
//! We'll describe the implementation and strategy, but note that most callers
//! should use `PlacesDb::begin_transaction()`, which will do the right thing
//! for your db type.
//!
//! The idea is that anything that uses the sync connection should use
//! `chunked_coop_trransaction`. Code using this should regularly call
//! `maybe_commit()`, and every second, will commit the transaction and start
//! a new one.
//!
//! This means that in theory the other writable connection can start
//! transactions and should block for a max of 1 second - well under the 5
//! seconds before that other writer will fail with a SQLITE_BUSY or similar error.
//!
//! However, in practice we see the writer thread being starved - even though
//! it's waiting for a lock, the sync thread still manages to re-get the lock.
//! In other words, the locks used by sqlite aren't "fair".
//!
//! So we mitigate this with a simple approach that works fine within our
//! "exactly 2 writers" constraints:
//! * Each database connection shares a mutex.
//! * Before starting a transaction, each connection locks the mutex.
//! * It then starts an "immediate" transaction - because sqlite now holds a
//!   lock on our behalf, we release the lock on the mutex.
//!
//! In other words, the lock is held only while obtaining the DB lock, then
//! immediately released.
//!
//! The end result here is that if either connection is waiting for the
//! database lock because the other already holds it, the waiting one is
//! guaranteed to get the database lock next.
//!
//! One additional wrinkle here is that even if there was exactly one writer,
//! there's still a possibility of SQLITE_BUSY if the database is being
//! checkpointed. So we handle that case and perform exactly 1 retry.

use crate::api::places_api::ConnectionType;
use crate::db::PlacesDb;
use crate::error::*;
use rusqlite::{Connection, TransactionBehavior};
use sql_support::{ConnExt, UncheckedTransaction};
use std::ops::Deref;
use std::sync::Mutex;
use std::time::{Duration, Instant};

impl PlacesDb {
    /// Begin a ChunkedCoopTransaction. Must be called from the
    /// sync connection, see module doc for details.
    pub(super) fn chunked_coop_trransaction(&self) -> Result<ChunkedCoopTransaction<'_>> {
        // Note: if there's actually a reason for a write conn to take this, we
        // can consider relaxing this. It's not required for correctness, just happens
        // to be the right choice for everything we expose and plan on exposing.
        assert_eq!(
            self.conn_type(),
            ConnectionType::Sync,
            "chunked_coop_trransaction must only be called by the Sync connection"
        );
        // Note that we don't allow commit_after as a param because it
        // is closely related to the timeouts configured on the database
        // itself.
        let commit_after = Duration::from_millis(1000);
        Ok(ChunkedCoopTransaction::new(
            self.conn(),
            commit_after,
            &self.coop_tx_lock,
        )?)
    }

    /// Begin a "coop" transaction. Must be called from the write connection, see
    /// module doc for details.
    pub(super) fn coop_transaction(&self) -> Result<UncheckedTransaction<'_>> {
        // Only validate tranaction types for ConnectionType::ReadWrite.
        assert_eq!(
            self.conn_type(),
            ConnectionType::ReadWrite,
            "coop_transaction must only be called on the ReadWrite connection"
        );
        let _lock = self.coop_tx_lock.lock().unwrap();
        get_tx_with_retry_on_locked(self.conn())
    }
}

/// This transaction is suitable for when a transaction is used purely for
/// performance reasons rather than for data-integrity reasons, or when it's
/// used for integrity but held longer than strictly necessary for performance
/// reasons (ie, when it could be multiple transactions and still guarantee
/// integrity.) Examples of this might be for performance when updating a larger
/// number of rows, but data integrity concerns could be addressed by using
/// multiple, smaller transactions.
///
/// You should regularly call .maybe_commit() as part of your
/// processing, and if the current transaction has been open for greater than
/// some duration the transaction will be committed and another one
/// started. You should always call .commit() at the end. Note that there is
/// no .rollback() method as it will be very difficult to work out what was
/// previously commited and therefore what was rolled back - if you need to
/// explicitly roll-back, this probably isn't what you should be using. Note
/// that SQLite might rollback for its own reasons though.
///
/// Note that this can still be used for transactions which ensure data
/// integrity. For example, if you are processing a large group of items, and
/// each individual item requires multiple updates, you will probably want to
/// ensure you call .maybe_commit() after every item rather than after
/// each individual database update.
pub struct ChunkedCoopTransaction<'conn> {
    tx: UncheckedTransaction<'conn>,
    commit_after: Duration,
    coop: &'conn Mutex<()>,
}

impl<'conn> ChunkedCoopTransaction<'conn> {
    /// Begin a new transaction which may be split into multiple transactions
    /// for performance reasons. Cannot be nested, but this is not
    /// enforced - however, it is enforced by SQLite; use a rusqlite `savepoint`
    /// for nested transactions.
    pub fn new(
        conn: &'conn Connection,
        commit_after: Duration,
        coop: &'conn Mutex<()>,
    ) -> Result<Self> {
        let _lock = coop.lock().unwrap();
        let tx = get_tx_with_retry_on_locked(conn)?;
        Ok(Self {
            tx,
            commit_after,
            coop,
        })
    }

    /// Returns `true` if the current transaction has been open for longer than
    /// the requested time, and should be committed; `false` otherwise. In most
    /// cases, there's no need to use this method, since `maybe_commit()` does
    /// so internally. It's exposed for consumers that need to run additional
    /// pre-commit logic, like cleaning up temp tables.
    ///
    /// If this method returns `true`, it's guaranteed that `maybe_commit()`
    /// will commit the transaction.
    #[inline]
    pub fn should_commit(&self) -> bool {
        self.tx.started_at.elapsed() >= self.commit_after
    }

    /// Checks to see if we have held a transaction for longer than the
    /// requested time, and if so, commits the current transaction and opens
    /// another.
    #[inline]
    pub fn maybe_commit(&mut self) -> Result<()> {
        if self.should_commit() {
            log::debug!("ChunkedCoopTransaction commiting after taking allocated time");
            self.commit_and_start_new_tx()?;
        }
        Ok(())
    }

    fn commit_and_start_new_tx(&mut self) -> Result<()> {
        // We can't call self.tx.commit() here as it wants to consume
        // self.tx, and we can't set up the new self.tx first as then
        // we'll be trying to start a new transaction while the current
        // one is in progress. So explicitly set the finished flag on it.
        self.tx.finished = true;
        self.tx.execute_batch("COMMIT")?;
        // acquire a lock on our cooperator - if our only other writer
        // thread holds a write lock we'll block until it is released.
        // Note however that sqlite might still return a locked error if the
        // database is being checkpointed - so we still perform exactly 1 retry,
        // which we do while we have the lock, because we don't want our other
        // write connection to win this race either.
        let _lock = self.coop.lock().unwrap();
        self.tx = get_tx_with_retry_on_locked(self.tx.conn)?;
        Ok(())
    }

    /// Consumes and commits a ChunkedCoopTransaction transaction.
    pub fn commit(self) -> Result<()> {
        self.tx.commit()?;
        Ok(())
    }

    /// Consumes and rolls a ChunkedCoopTransaction, but potentially only back
    /// to the last `maybe_commit`.
    pub fn rollback(self) -> Result<()> {
        self.tx.rollback()?;
        Ok(())
    }
}

impl<'conn> Deref for ChunkedCoopTransaction<'conn> {
    type Target = Connection;

    #[inline]
    fn deref(&self) -> &Connection {
        self.tx.conn
    }
}

impl<'conn> ConnExt for ChunkedCoopTransaction<'conn> {
    #[inline]
    fn conn(&self) -> &Connection {
        &*self
    }
}

// A helper that attempts to get an Immediate lock on the DB. If it fails with
// a "busy" or "locked" error, it does exactly 1 retry.
fn get_tx_with_retry_on_locked(conn: &Connection) -> Result<UncheckedTransaction<'_>> {
    let behavior = TransactionBehavior::Immediate;
    match UncheckedTransaction::new(conn, behavior) {
        Ok(tx) => Ok(tx),
        Err(rusqlite::Error::SqliteFailure(err, _))
            if err.code == rusqlite::ErrorCode::DatabaseBusy
                || err.code == rusqlite::ErrorCode::DatabaseLocked =>
        {
            // retry the lock - we assume that this lock request still
            // blocks for the default period, so we don't need to sleep
            // etc.
            let started_at = Instant::now();
            log::warn!("Attempting to get a read lock failed - doing one retry");
            let tx = UncheckedTransaction::new(conn, behavior).map_err(|err| {
                log::warn!("Retrying the lock failed after {:?}", started_at.elapsed());
                err
            })?;
            log::info!("Retrying the lock worked after {:?}", started_at.elapsed());
            Ok(tx)
        }
        Err(e) => Err(e.into()),
    }
}
