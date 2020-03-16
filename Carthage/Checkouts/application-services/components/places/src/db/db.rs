/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use super::schema;
use crate::api::places_api::ConnectionType;
use crate::error::*;
use rusqlite::Connection;
use sql_support::{ConnExt, SqlInterruptHandle, SqlInterruptScope};
use std::ops::Deref;
use std::path::Path;

use std::sync::{atomic::AtomicUsize, Arc, Mutex};

pub const MAX_VARIABLE_NUMBER: usize = 999;

#[derive(Debug)]
pub struct PlacesDb {
    pub db: Connection,
    conn_type: ConnectionType,
    interrupt_counter: Arc<AtomicUsize>,
    api_id: usize,
    in_memory: bool,
    pub(super) coop_tx_lock: Arc<Mutex<()>>,
}

impl PlacesDb {
    pub fn with_connection(
        db: Connection,
        conn_type: ConnectionType,
        api_id: usize,
        coop_tx_lock: Arc<Mutex<()>>,
        in_memory: bool,
    ) -> Result<Self> {
        let initial_pragmas = "
            -- The value we use was taken from Desktop Firefox, and seems necessary to
            -- help ensure good performance on autocomplete-style queries. The default value is 1024,
            -- which the SQLcipher docs themselves say is too small and should be changed.
            PRAGMA page_size = 32768;

            -- Disable calling mlock/munlock for every malloc/free.
            -- In practice this results in a massive speedup, especially
            -- for insert-heavy workloads.
            PRAGMA cipher_memory_security = false;

            -- `temp_store = 2` is required on Android to force the DB to keep temp
            -- files in memory, since on Android there's no tmp partition. See
            -- https://github.com/mozilla/mentat/issues/505. Ideally we'd only
            -- do this on Android, and/or allow caller to configure it.
            -- (although see also bug 1313021, where Firefox enabled it for both
            -- Android and 64bit desktop builds)
            PRAGMA temp_store = 2;

            -- 6MiB, same as the value used for `promiseLargeCacheDBConnection` in PlacesUtils,
            -- which is used to improve query performance for autocomplete-style queries (by
            -- UnifiedComplete). Note that SQLite uses a negative value for this pragma to indicate
            -- that it's in units of KiB.
            PRAGMA cache_size = -6144;

            -- We want foreign-key support.
            PRAGMA foreign_keys = ON;

            -- we unconditionally want write-ahead-logging mode
            PRAGMA journal_mode=WAL;

            -- How often to autocheckpoint (in units of pages).
            -- 2048000 (our max desired WAL size) / 32760 (page size).
            PRAGMA wal_autocheckpoint=62
        ";

        db.execute_batch(initial_pragmas)?;
        define_functions(&db)?;
        db.set_prepared_statement_cache_capacity(128);
        let res = Self {
            db,
            conn_type,
            // The API sets this explicitly.
            api_id,
            interrupt_counter: Arc::new(AtomicUsize::new(0)),
            coop_tx_lock,
            in_memory,
        };
        match res.conn_type() {
            // For read-only connections, we can avoid opening a transaction,
            // since we know we won't be migrating or initializing anything.
            ConnectionType::ReadOnly => {}
            _ => {
                // Even though we're the owner of the db, we need it to be an unchecked tx
                // since we want to pass &PlacesDb and not &Connection to schema::init.
                let tx = res.unchecked_transaction()?;
                schema::init(&res)?;
                tx.commit()?;
            }
        }

        Ok(res)
    }

    pub fn open(
        path: impl AsRef<Path>,
        conn_type: ConnectionType,
        api_id: usize,
        coop_tx_lock: Arc<Mutex<()>>,
    ) -> Result<Self> {
        Ok(Self::with_connection(
            Connection::open_with_flags(path, conn_type.rusqlite_flags())?,
            conn_type,
            api_id,
            coop_tx_lock,
            false,
        )?)
    }

    #[cfg(test)]
    // Useful for some tests (although most tests should use helper functions
    // in api::places_api::test)
    pub fn open_in_memory(conn_ty: ConnectionType) -> Result<Self> {
        Ok(Self::with_connection(
            Connection::open_in_memory()?,
            conn_ty,
            0,
            Arc::new(Mutex::new(())),
            true,
        )?)
    }

    pub fn new_interrupt_handle(&self) -> SqlInterruptHandle {
        SqlInterruptHandle::new(
            self.db.get_interrupt_handle(),
            self.interrupt_counter.clone(),
        )
    }

    #[inline]
    pub fn begin_interrupt_scope(&self) -> SqlInterruptScope {
        SqlInterruptScope::new(self.interrupt_counter.clone())
    }

    #[inline]
    pub fn conn_type(&self) -> ConnectionType {
        self.conn_type
    }

    #[inline]
    pub fn api_id(&self) -> usize {
        self.api_id
    }

    #[inline]
    pub fn is_in_memory(&self) -> bool {
        self.in_memory
    }
}

impl Drop for PlacesDb {
    fn drop(&mut self) {
        // In line with both the recommendations from SQLite and the behavior of places in
        // Database.cpp, we run `PRAGMA optimize` before closing the connection.
        let res = self.db.execute_batch("PRAGMA optimize(0x02);");
        if let Err(e) = res {
            log::warn!("Failed to execute pragma optimize (DB locked?): {}", e);
        }
    }
}

impl ConnExt for PlacesDb {
    #[inline]
    fn conn(&self) -> &Connection {
        &self.db
    }
}

impl Deref for PlacesDb {
    type Target = Connection;
    #[inline]
    fn deref(&self) -> &Connection {
        &self.db
    }
}

fn define_functions(c: &Connection) -> Result<()> {
    c.create_scalar_function("get_prefix", 1, true, sql_fns::get_prefix)?;
    c.create_scalar_function("get_host_and_port", 1, true, sql_fns::get_host_and_port)?;
    c.create_scalar_function(
        "strip_prefix_and_userinfo",
        1,
        true,
        sql_fns::strip_prefix_and_userinfo,
    )?;
    c.create_scalar_function("reverse_host", 1, true, sql_fns::reverse_host)?;
    c.create_scalar_function("autocomplete_match", 10, true, sql_fns::autocomplete_match)?;
    c.create_scalar_function("hash", -1, true, sql_fns::hash)?;
    c.create_scalar_function("now", 0, false, sql_fns::now)?;
    c.create_scalar_function("generate_guid", 0, false, sql_fns::generate_guid)?;
    Ok(())
}

pub(crate) mod sql_fns {
    use crate::api::matcher::{split_after_host_and_port, split_after_prefix};
    use crate::hash;
    use crate::match_impl::{AutocompleteMatch, MatchBehavior, SearchBehavior};
    use crate::types::Timestamp;
    use rusqlite::{functions::Context, types::ValueRef, Error, Result};
    use sync_guid::Guid as SyncGuid;

    // Helpers for define_functions
    fn get_raw_str<'a>(ctx: &'a Context<'_>, fname: &'static str, idx: usize) -> Result<&'a str> {
        ctx.get_raw(idx).as_str().map_err(|e| {
            Error::UserFunctionError(format!("Bad arg {} to '{}': {}", idx, fname, e).into())
        })
    }

    fn get_raw_opt_str<'a>(
        ctx: &'a Context<'_>,
        fname: &'static str,
        idx: usize,
    ) -> Result<Option<&'a str>> {
        let raw = ctx.get_raw(idx);
        if raw == ValueRef::Null {
            return Ok(None);
        }
        Ok(Some(raw.as_str().map_err(|e| {
            Error::UserFunctionError(format!("Bad arg {} to '{}': {}", idx, fname, e).into())
        })?))
    }

    // Note: The compiler can't meaningfully inline these, but if we don't put
    // #[inline(never)] on them they get "inlined" into a temporary Box<FnMut>,
    // which doesn't have a name (and itself doesn't get inlined). Adding
    // #[inline(never)] ensures they show up in profiles.

    #[inline(never)]
    pub fn hash(ctx: &Context<'_>) -> rusqlite::Result<Option<i64>> {
        Ok(match ctx.len() {
            1 => {
                // This is a deterministic function, which means sqlite
                // does certain optimizations which means hash() may be called
                // with a null value even though the query prevents the null
                // value from actually being used. As a special case, we return
                // null when the input is NULL. We return NULL instead of zero
                // because the hash columns are NOT NULL, so attempting to
                // actually use the null should fail.
                get_raw_opt_str(ctx, "hash", 0)?.map(|value| hash::hash_url(value) as i64)
            }
            2 => {
                let value = get_raw_opt_str(ctx, "hash", 0)?;
                let mode = get_raw_str(ctx, "hash", 1)?;
                if let Some(value) = value {
                    Some(match mode {
                        "" => hash::hash_url(&value),
                        "prefix_lo" => hash::hash_url_prefix(&value, hash::PrefixMode::Lo),
                        "prefix_hi" => hash::hash_url_prefix(&value, hash::PrefixMode::Hi),
                        arg => {
                            return Err(rusqlite::Error::UserFunctionError(format!(
                                "`hash` second argument must be either '', 'prefix_lo', or 'prefix_hi', got {:?}.",
                                arg).into()));
                        }
                    } as i64)
                } else {
                    None
                }
            }
            n => {
                return Err(rusqlite::Error::UserFunctionError(
                    format!("`hash` expects 1 or 2 arguments, got {}.", n).into(),
                ));
            }
        })
    }

    #[inline(never)]
    pub fn autocomplete_match(ctx: &Context<'_>) -> Result<bool> {
        let search_str = get_raw_str(ctx, "autocomplete_match", 0)?;
        let url_str = get_raw_str(ctx, "autocomplete_match", 1)?;
        let title_str = get_raw_opt_str(ctx, "autocomplete_match", 2)?.unwrap_or_default();
        let tags = get_raw_opt_str(ctx, "autocomplete_match", 3)?.unwrap_or_default();
        let visit_count = ctx.get::<u32>(4)?;
        let typed = ctx.get::<bool>(5)?;
        let bookmarked = ctx.get::<bool>(6)?;
        let open_page_count = ctx.get::<Option<u32>>(7)?.unwrap_or(0);
        let match_behavior = ctx.get::<MatchBehavior>(8)?;
        let search_behavior = ctx.get::<SearchBehavior>(9)?;

        let matcher = AutocompleteMatch {
            search_str,
            url_str,
            title_str,
            tags,
            visit_count,
            typed,
            bookmarked,
            open_page_count,
            match_behavior,
            search_behavior,
        };
        Ok(matcher.invoke())
    }

    #[inline(never)]
    pub fn reverse_host(ctx: &Context<'_>) -> Result<String> {
        // We reuse this memory so no need for get_raw.
        let mut host = ctx.get::<String>(0)?;
        debug_assert!(host.is_ascii(), "Hosts must be Punycoded");

        host.make_ascii_lowercase();
        let mut rev_host_bytes = host.into_bytes();
        rev_host_bytes.reverse();
        rev_host_bytes.push(b'.');

        let rev_host = String::from_utf8(rev_host_bytes).map_err(|_err| {
            rusqlite::Error::UserFunctionError("non-punycode host provided to reverse_host!".into())
        })?;
        Ok(rev_host)
    }

    #[inline(never)]
    pub fn get_prefix(ctx: &Context<'_>) -> Result<String> {
        let href = get_raw_str(ctx, "get_prefix", 0)?;
        let (prefix, _) = split_after_prefix(&href);
        Ok(prefix.to_owned())
    }

    #[inline(never)]
    pub fn get_host_and_port(ctx: &Context<'_>) -> Result<String> {
        let href = get_raw_str(ctx, "get_host_and_port", 0)?;
        let (host_and_port, _) = split_after_host_and_port(&href);
        Ok(host_and_port.to_owned())
    }

    #[inline(never)]
    pub fn strip_prefix_and_userinfo(ctx: &Context<'_>) -> Result<String> {
        let href = get_raw_str(ctx, "strip_prefix_and_userinfo", 0)?;
        let (host_and_port, remainder) = split_after_host_and_port(&href);
        let mut res = String::with_capacity(host_and_port.len() + remainder.len() + 1);
        res += host_and_port;
        res += remainder;
        Ok(res)
    }

    #[inline(never)]
    pub fn now(_ctx: &Context<'_>) -> Result<Timestamp> {
        Ok(Timestamp::now())
    }

    #[inline(never)]
    pub fn generate_guid(_ctx: &Context<'_>) -> Result<SyncGuid> {
        Ok(SyncGuid::random())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rusqlite::NO_PARAMS;

    // Sanity check that we can create a database.
    #[test]
    fn test_open() {
        PlacesDb::open_in_memory(ConnectionType::ReadWrite).expect("no memory db");
    }

    #[test]
    fn test_reverse_host() {
        let conn = PlacesDb::open_in_memory(ConnectionType::ReadOnly).expect("no memory db");
        let rev_host: String = conn
            .db
            .query_row("SELECT reverse_host('www.mozilla.org')", NO_PARAMS, |row| {
                row.get(0)
            })
            .unwrap();
        assert_eq!(rev_host, "gro.allizom.www.");

        let rev_host: String = conn
            .db
            .query_row("SELECT reverse_host('')", NO_PARAMS, |row| row.get(0))
            .unwrap();
        assert_eq!(rev_host, ".");
    }
}
