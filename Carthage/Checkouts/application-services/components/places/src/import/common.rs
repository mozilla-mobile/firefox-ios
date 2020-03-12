/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::api::places_api::SyncConn;
use crate::error::*;
use crate::types::Timestamp;
use rusqlite::named_params;
use url::Url;

// sanitize_timestamp can't use `Timestamp::now();` directly because it needs
// to sanitize both created and modified, plus ensure modified isn't before
// created - which isn't possible with the non-monotonic timestamp.
// So we have a static `NOW`, which will be initialized the first time it is
// referenced, and that value subsequently used for every imported bookmark (and
// note that it's only used in cases where the existing timestamps are invalid.)
// This is fine for our use-case, where we do exactly one import as soon as the
// process starts.
lazy_static::lazy_static! {
    pub static ref NOW: Timestamp = Timestamp::now();
}

pub mod sql_fns {
    use crate::import::common::NOW;
    use crate::storage::URL_LENGTH_MAX;
    use crate::types::Timestamp;
    use rusqlite::{functions::Context, types::ValueRef, Result};
    use std::convert::TryFrom;
    use url::Url;

    #[inline(never)]
    pub fn sanitize_timestamp(ctx: &Context<'_>) -> Result<Timestamp> {
        let now = *NOW;
        let is_sane = |ts: Timestamp| -> bool { Timestamp::EARLIEST <= ts && ts <= now };
        if let Ok(ts) = ctx.get::<i64>(0) {
            let ts = Timestamp(u64::try_from(ts).unwrap_or(0));
            if is_sane(ts) {
                return Ok(ts);
            }
            // Maybe the timestamp was actually in μs?
            let ts = Timestamp(ts.as_millis() / 1000);
            if is_sane(ts) {
                return Ok(ts);
            }
        }
        Ok(now)
    }

    // Possibly better named as "normalize URL" - even in non-error cases, the
    // result string may not be the same href used passed as input.
    #[inline(never)]
    pub fn validate_url(ctx: &Context<'_>) -> Result<Option<String>> {
        let val = ctx.get_raw(0);
        let href = if let ValueRef::Text(s) = val {
            String::from_utf8_lossy(s).to_string()
        } else {
            return Ok(None);
        };
        if href.len() > URL_LENGTH_MAX {
            return Ok(None);
        }
        if let Ok(url) = Url::parse(&href) {
            Ok(Some(url.into_string()))
        } else {
            Ok(None)
        }
    }

    // Sanitize a text column into valid utf-8. Leave NULLs alone, but all other
    // types are converted to an empty string.
    #[inline(never)]
    pub fn sanitize_utf8(ctx: &Context<'_>) -> Result<Option<String>> {
        let val = ctx.get_raw(0);
        Ok(match val {
            ValueRef::Text(s) => Some(String::from_utf8_lossy(s).to_string()),
            ValueRef::Null => None,
            _ => Some("".to_owned()),
        })
    }
}

pub fn attached_database<'a>(
    conn: &'a SyncConn<'a>,
    path: &Url,
    db_alias: &'static str,
) -> Result<ExecuteOnDrop<'a>> {
    conn.execute_named(
        "ATTACH DATABASE :path AS :db_alias",
        named_params! {
            ":path": path.as_str(),
            ":db_alias": db_alias,
        },
    )?;
    Ok(ExecuteOnDrop {
        conn,
        sql: format!("DETACH DATABASE {};", db_alias),
    })
}

/// We use/abuse the mirror to perform our import, but need to clean it up
/// afterwards. This is an RAII helper to do so.
///
/// Ideally, you should call `execute_now` rather than letting this drop
/// automatically, as we can't report errors beyond logging when running
/// Drop.
pub struct ExecuteOnDrop<'a> {
    conn: &'a SyncConn<'a>,
    sql: String,
}

impl<'a> ExecuteOnDrop<'a> {
    pub fn new(conn: &'a SyncConn<'a>, sql: String) -> Self {
        Self { conn, sql }
    }

    pub fn execute_now(self) -> Result<()> {
        self.conn.execute_batch(&self.sql)?;
        // Don't run our `drop` function.
        std::mem::forget(self);
        Ok(())
    }
}

impl Drop for ExecuteOnDrop<'_> {
    fn drop(&mut self) {
        if let Err(e) = self.conn.execute_batch(&self.sql) {
            log::error!("Failed to clean up after import! {}", e);
            log::debug!("  Failed query: {}", &self.sql);
        }
    }
}
