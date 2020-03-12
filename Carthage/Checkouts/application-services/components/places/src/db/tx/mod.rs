/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

mod coop_transaction;

use crate::api::places_api::ConnectionType;
use crate::error::*;
use coop_transaction::ChunkedCoopTransaction;
use rusqlite::Connection;
use sql_support::{ConnExt, UncheckedTransaction};

macro_rules! debug_complaint {
    ($($fmt_args:tt)*) => {
        log::error!($($fmt_args)*);
        if cfg!(debug_assertions) {
            panic!($($fmt_args)*);
        }
    };
}
/// High level transaction type which "does the right thing" for you.
/// Construct one with `PlacesDb::begin_transaction()`.
pub struct PlacesTransaction<'conn>(PlacesTransactionRepr<'conn>);

/// Only separated from PlacesTransaction so that the internals of the former
/// are private (so that it can't be `matched` on, for example)
enum PlacesTransactionRepr<'conn> {
    ChunkedWrite(ChunkedCoopTransaction<'conn>),
    UnchunkedWrite(UncheckedTransaction<'conn>),
    // Note: these might seem pointless, but can allow us to ensure consistency
    // between separate reads.
    ReadOnly(UncheckedTransaction<'conn>),
}

impl<'conn> PlacesTransaction<'conn> {
    /// Returns `true` if the current transaction should be committed at the
    /// earliest opportunity.
    #[inline]
    pub fn should_commit(&self) -> bool {
        match &self.0 {
            PlacesTransactionRepr::ChunkedWrite(tx) => tx.should_commit(),
            _ => true,
        }
    }

    /// - For transactions on sync connnections: Checks to see if we have held a
    ///   transaction for longer than the requested time, and if so, commits the
    ///   current transaction and opens another.
    /// - For transactions on other connections: `debug_assert!`s, or logs a
    ///   warning and does nothing.
    #[inline]
    pub fn maybe_commit(&mut self) -> Result<()> {
        if let PlacesTransactionRepr::ChunkedWrite(tx) = &mut self.0 {
            tx.maybe_commit()?;
        } else {
            debug_complaint!("maybe_commit called on a non-chunked transaction");
        }
        Ok(())
    }

    /// Consumes and commits a PlacesTransaction transaction.
    pub fn commit(self) -> Result<()> {
        match self.0 {
            PlacesTransactionRepr::ChunkedWrite(t) => t.commit()?,
            PlacesTransactionRepr::UnchunkedWrite(t) => t.commit()?,
            PlacesTransactionRepr::ReadOnly(t) => t.commit()?,
        };
        Ok(())
    }

    /// Consumes and attempst to roll back a PlacesTransaction. Note that if
    /// maybe_commit has been called, this may only roll back as far as that
    /// call.
    pub fn rollback(self) -> Result<()> {
        match self.0 {
            PlacesTransactionRepr::ChunkedWrite(t) => t.rollback()?,
            PlacesTransactionRepr::UnchunkedWrite(t) => t.rollback()?,
            PlacesTransactionRepr::ReadOnly(t) => t.rollback()?,
        };
        Ok(())
    }
}

impl super::PlacesDb {
    /// Begin the "correct" transaction type for this connection.
    ///
    /// - For Sync connections, begins a chunked coop transaction.
    /// - for ReadWrite connections, begins a normal coop transaction
    /// - for ReadOnly connections, begins an unchecked transaction.
    pub fn begin_transaction(&self) -> Result<PlacesTransaction<'_>> {
        Ok(PlacesTransaction(match self.conn_type() {
            ConnectionType::Sync => {
                PlacesTransactionRepr::ChunkedWrite(self.chunked_coop_trransaction()?)
            }
            ConnectionType::ReadWrite => {
                PlacesTransactionRepr::UnchunkedWrite(self.coop_transaction()?)
            }
            ConnectionType::ReadOnly => {
                // Use an unchecked transaction with no locking.
                PlacesTransactionRepr::ReadOnly(self.unchecked_transaction()?)
            }
        }))
    }
}

impl<'conn> std::ops::Deref for PlacesTransaction<'conn> {
    type Target = Connection;

    fn deref(&self) -> &Connection {
        match &self.0 {
            PlacesTransactionRepr::ChunkedWrite(t) => &t,
            PlacesTransactionRepr::UnchunkedWrite(t) => &t,
            PlacesTransactionRepr::ReadOnly(t) => &t,
        }
    }
}

impl<'conn> ConnExt for PlacesTransaction<'conn> {
    #[inline]
    fn conn(&self) -> &Connection {
        &*self
    }
}
