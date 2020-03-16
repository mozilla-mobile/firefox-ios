/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
use crate::error::Result;
use rusqlite::{
    types::{FromSql, ToSql},
    Connection,
};
use sql_support::ConnExt;

// For type safety
#[derive(Copy, Clone, PartialEq, Eq, PartialOrd)]
pub(crate) struct MetaKey(pub &'static str);

pub(crate) const COLLECTION_NAME: MetaKey = MetaKey("remerge/collection-name");
pub(crate) const LOCAL_SCHEMA_VERSION: MetaKey = MetaKey("remerge/local-schema");
pub(crate) const NATIVE_SCHEMA_VERSION: MetaKey = MetaKey("remerge/native-schema");
pub(crate) const OWN_CLIENT_ID: MetaKey = MetaKey("remerge/client-id");
pub(crate) const CHANGE_COUNTER: MetaKey = MetaKey("remerge/change-counter");
// pub(crate) const LAST_SYNC_SERVER_MS: MetaKey = MetaKey("remerge/server-last-sync-ms");

pub(crate) fn put(db: &Connection, key: MetaKey, value: &dyn ToSql) -> Result<()> {
    db.execute_named_cached(
        "REPLACE INTO metadata (key, value) VALUES (:key, :value)",
        &[(":key", &key.0), (":value", value)],
    )?;
    Ok(())
}

pub(crate) fn try_get<T: FromSql>(db: &Connection, key: MetaKey) -> Result<Option<T>> {
    let res = db.try_query_one(
        "SELECT value FROM metadata WHERE key = :key",
        &[(":key", &key.0)],
        true,
    )?;
    Ok(res)
}

pub(crate) fn get<T: FromSql>(db: &Connection, key: MetaKey) -> Result<T> {
    let res = db.query_row_and_then(
        "SELECT value FROM metadata WHERE key = ?",
        rusqlite::params![key.0],
        |row| row.get(0),
    )?;
    Ok(res)
}

// pub(crate) fn delete_meta(db: &PlacesDb, key: MetaKey) -> Result<()> {
//     db.execute_named_cached("DELETE FROM moz_meta WHERE key = :key", &[(":key", &key.0)])?;
//     Ok(())
// }
