/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// A "storage" module - this module is intended to be the layer between the
// API and the database.

pub mod bookmarks;
pub mod history;
pub mod tags;

use crate::db::PlacesDb;
use crate::error::{ErrorKind, InvalidPlaceInfo, Result};
use crate::msg_types::HistoryVisitInfo;
use crate::types::{SyncStatus, Timestamp, VisitTransition};
use rusqlite::types::{FromSql, FromSqlResult, ToSql, ToSqlOutput, ValueRef};
use rusqlite::Result as RusqliteResult;
use rusqlite::Row;
use serde_derive::*;
use sql_support::{self, ConnExt};
use std::fmt;
use sync_guid::Guid as SyncGuid;
use url::Url;

/// From https://searchfox.org/mozilla-central/rev/93905b660f/toolkit/components/places/PlacesUtils.jsm#189
pub const URL_LENGTH_MAX: usize = 65536;
pub const TITLE_LENGTH_MAX: usize = 4096;
pub const TAG_LENGTH_MAX: usize = 100;
// pub const DESCRIPTION_LENGTH_MAX: usize = 256;

// Typesafe way to manage RowIds. Does it make sense? A better way?
#[derive(Debug, Copy, Clone, PartialEq, PartialOrd, Eq, Ord, Deserialize, Serialize, Default)]
pub struct RowId(pub i64);

impl From<RowId> for i64 {
    // XXX - ToSql!
    #[inline]
    fn from(id: RowId) -> Self {
        id.0
    }
}

impl fmt::Display for RowId {
    #[inline]
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl ToSql for RowId {
    fn to_sql(&self) -> RusqliteResult<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(self.0))
    }
}

impl FromSql for RowId {
    fn column_result(value: ValueRef<'_>) -> FromSqlResult<Self> {
        value.as_i64().map(RowId)
    }
}

#[derive(Debug)]
pub struct PageInfo {
    pub url: Url,
    pub guid: SyncGuid,
    pub row_id: RowId,
    pub title: String,
    pub hidden: bool,
    pub typed: u32,
    pub frecency: i32,
    pub visit_count_local: i32,
    pub visit_count_remote: i32,
    pub last_visit_date_local: Timestamp,
    pub last_visit_date_remote: Timestamp,
    pub sync_status: SyncStatus,
    pub sync_change_counter: u32,
}

impl PageInfo {
    pub fn from_row(row: &Row<'_>) -> Result<Self> {
        Ok(Self {
            url: Url::parse(&row.get::<_, String>("url")?)?,
            guid: row.get::<_, String>("guid")?.into(),
            row_id: row.get("id")?,
            title: row.get::<_, Option<String>>("title")?.unwrap_or_default(),
            hidden: row.get("hidden")?,
            typed: row.get("typed")?,

            frecency: row.get("frecency")?,
            visit_count_local: row.get("visit_count_local")?,
            visit_count_remote: row.get("visit_count_remote")?,

            last_visit_date_local: row
                .get::<_, Option<Timestamp>>("last_visit_date_local")?
                .unwrap_or_default(),
            last_visit_date_remote: row
                .get::<_, Option<Timestamp>>("last_visit_date_remote")?
                .unwrap_or_default(),

            sync_status: SyncStatus::from_u8(row.get::<_, u8>("sync_status")?),
            sync_change_counter: row
                .get::<_, Option<u32>>("sync_change_counter")?
                .unwrap_or_default(),
        })
    }
}

// fetch_page_info gives you one of these.
#[derive(Debug)]
pub struct FetchedPageInfo {
    pub page: PageInfo,
    // XXX - not clear what this is used for yet, and whether it should be local, remote or either?
    // The sql below isn't quite sure either :)
    pub last_visit_id: Option<RowId>,
}

impl FetchedPageInfo {
    pub fn from_row(row: &Row<'_>) -> Result<Self> {
        Ok(Self {
            page: PageInfo::from_row(row)?,
            last_visit_id: row.get::<_, Option<RowId>>("last_visit_id")?,
        })
    }
}

// History::FetchPageInfo
pub fn fetch_page_info(db: &PlacesDb, url: &Url) -> Result<Option<FetchedPageInfo>> {
    let sql = "
      SELECT guid, url, id, title, hidden, typed, frecency,
             visit_count_local, visit_count_remote,
             last_visit_date_local, last_visit_date_remote,
             sync_status, sync_change_counter,
             (SELECT id FROM moz_historyvisits
              WHERE place_id = h.id
                AND (visit_date = h.last_visit_date_local OR
                     visit_date = h.last_visit_date_remote)) AS last_visit_id
      FROM moz_places h
      WHERE url_hash = hash(:page_url) AND url = :page_url";
    Ok(db.try_query_row(
        sql,
        &[(":page_url", &url.clone().into_string())],
        FetchedPageInfo::from_row,
        true,
    )?)
}

fn new_page_info(db: &PlacesDb, url: &Url, new_guid: Option<SyncGuid>) -> Result<PageInfo> {
    let guid = match new_guid {
        Some(guid) => guid,
        None => SyncGuid::random(),
    };
    let url_str = url.as_str();
    if url_str.len() > URL_LENGTH_MAX {
        // Generally callers check this first (bookmarks don't, history does).
        return Err(ErrorKind::InvalidPlaceInfo(InvalidPlaceInfo::UrlTooLong).into());
    }
    let sql = "INSERT INTO moz_places (guid, url, url_hash)
               VALUES (:guid, :url, hash(:url))";
    db.execute_named_cached(sql, &[(":guid", &guid), (":url", &url_str)])?;
    Ok(PageInfo {
        url: url.clone(),
        guid,
        row_id: RowId(db.conn().last_insert_rowid()),
        title: "".into(),
        hidden: true, // will be set to false as soon as a non-hidden visit appears.
        typed: 0,
        frecency: -1,
        visit_count_local: 0,
        visit_count_remote: 0,
        last_visit_date_local: Timestamp(0),
        last_visit_date_remote: Timestamp(0),
        sync_status: SyncStatus::New,
        sync_change_counter: 0,
    })
}

impl HistoryVisitInfo {
    pub(crate) fn from_row(row: &rusqlite::Row<'_>) -> Result<Self> {
        let visit_type = VisitTransition::from_primitive(row.get::<_, u8>("visit_type")?)
            // Do we have an existing error we use for this? For now they
            // probably don't care too much about VisitTransition, so this
            // is fine.
            .unwrap_or(VisitTransition::Link);
        let visit_date: Timestamp = row.get("visit_date")?;
        Ok(Self {
            url: row.get("url")?,
            title: row.get("title")?,
            timestamp: visit_date.0 as i64,
            visit_type: visit_type as i32,
            is_hidden: row.get("hidden")?,
        })
    }
}

pub fn run_maintenance(conn: &PlacesDb) -> Result<()> {
    conn.execute_all(&[
        "VACUUM",
        "PRAGMA optimize",
        "PRAGMA wal_checkpoint(PASSIVE)",
    ])?;
    Ok(())
}

pub(crate) fn put_meta(db: &PlacesDb, key: &str, value: &dyn ToSql) -> Result<()> {
    db.execute_named_cached(
        "REPLACE INTO moz_meta (key, value) VALUES (:key, :value)",
        &[(":key", &key), (":value", value)],
    )?;
    Ok(())
}

pub(crate) fn get_meta<T: FromSql>(db: &PlacesDb, key: &str) -> Result<Option<T>> {
    let res = db.try_query_one(
        "SELECT value FROM moz_meta WHERE key = :key",
        &[(":key", &key)],
        true,
    )?;
    Ok(res)
}

pub(crate) fn delete_meta(db: &PlacesDb, key: &str) -> Result<()> {
    db.execute_named_cached("DELETE FROM moz_meta WHERE key = :key", &[(":key", &key)])?;
    Ok(())
}

/// Delete all items in the temp tables we use for staging changes.
pub(crate) fn delete_pending_temp_tables(conn: &PlacesDb) -> Result<()> {
    conn.execute_batch(
        "DELETE FROM moz_updateoriginsupdate_temp;
         DELETE FROM moz_updateoriginsdelete_temp;
         DELETE FROM moz_updateoriginsinsert_temp;",
    )?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::places_api::test::new_mem_connection;

    #[test]
    fn test_meta() {
        let conn = new_mem_connection();
        let value1 = "value 1".to_string();
        let value2 = "value 2".to_string();
        assert!(get_meta::<String>(&conn, "foo")
            .expect("should get")
            .is_none());
        put_meta(&conn, "foo", &value1).expect("should put");
        assert_eq!(
            get_meta(&conn, "foo").expect("should get new val"),
            Some(value1)
        );
        put_meta(&conn, "foo", &value2).expect("should put an existing value");
        assert_eq!(get_meta(&conn, "foo").expect("should get"), Some(value2));
        delete_meta(&conn, "foo").expect("should delete");
        assert!(get_meta::<String>(&conn, &"foo")
            .expect("should get non-existing")
            .is_none());
        delete_meta(&conn, "foo").expect("delete non-existing should work");
    }
}
