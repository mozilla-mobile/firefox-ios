/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use super::record::BookmarkRecordId;
use super::{SyncedBookmarkKind, SyncedBookmarkValidity};
use crate::error::*;
use crate::storage::{
    bookmarks::maybe_truncate_title,
    tags::{validate_tag, ValidatedTag},
    URL_LENGTH_MAX,
};
use rusqlite::Connection;
use serde_json::Value as JsonValue;
use sql_support::{self, ConnExt};
use std::{collections::HashSet, iter};
use sync15::ServerTimestamp;
use sync_guid::Guid as SyncGuid;
use url::Url;

// From Desktop's Ci.nsINavHistoryQueryOptions, but we define it as a str
// as that's how we use it here.
const RESULTS_AS_TAG_CONTENTS: &str = "7";

/// Manages the application of incoming records into the moz_bookmarks_synced
/// and related tables.
pub struct IncomingApplicator<'a> {
    db: &'a Connection,
}

impl<'a> IncomingApplicator<'a> {
    pub fn new(db: &'a Connection) -> Self {
        Self { db }
    }

    pub fn apply_payload(
        &self,
        payload: sync15::Payload,
        timestamp: ServerTimestamp,
    ) -> Result<()> {
        if payload.is_tombstone() {
            self.store_incoming_tombstone(
                timestamp,
                BookmarkRecordId::from_payload_id(payload.id).as_guid(),
            )?;
        } else {
            let value: JsonValue = payload.into();
            match value["type"].as_str() {
                Some("bookmark") => self.store_incoming_bookmark(timestamp, &value)?,
                Some("query") => self.store_incoming_query(timestamp, &value)?,
                Some("folder") => self.store_incoming_folder(timestamp, &value)?,
                Some("livemark") => self.store_incoming_livemark(timestamp, &value)?,
                Some("separator") => self.store_incoming_sep(timestamp, &value)?,
                _ => {
                    return Err(
                        ErrorKind::UnsupportedIncomingBookmarkType(value["type"].clone()).into(),
                    )
                }
            };
        }
        Ok(())
    }

    fn store_incoming_bookmark(&self, modified: ServerTimestamp, b: &JsonValue) -> Result<()> {
        let mut validity = SyncedBookmarkValidity::Valid;

        let record_id = unpack_id("id", b)?;
        let parent_record_id = unpack_optional_id("parentid", b);
        let date_added = unpack_optional_i64("dateAdded", b, &mut validity);
        let title = unpack_optional_str("title", b, &mut validity);
        let keyword = unpack_optional_str("keyword", b, &mut validity);

        let raw_tags = &b["tags"];
        let tags = if let Some(array) = raw_tags.as_array() {
            let mut seen = HashSet::with_capacity(array.len());
            for v in array {
                if let JsonValue::String(s) = v {
                    let tag = match validate_tag(&s) {
                        ValidatedTag::Invalid(t) => {
                            log::trace!("Incoming bookmark has invalid tag: {:?}", t);
                            set_reupload(&mut validity);
                            continue;
                        }
                        ValidatedTag::Normalized(t) => {
                            set_reupload(&mut validity);
                            t
                        }
                        ValidatedTag::Original(t) => t,
                    };
                    if !seen.insert(tag) {
                        log::trace!("Incoming bookmark has duplicate tag: {:?}", tag);
                        set_reupload(&mut validity);
                    }
                } else {
                    log::trace!("Incoming bookmark has unexpected tag: {:?}", v);
                    set_reupload(&mut validity);
                }
            }
            seen
        } else {
            if !raw_tags.is_array() {
                log::trace!("Incoming bookmark has unexpected tags list: {:?}", raw_tags);
            }
            HashSet::new()
        };

        let url = unpack_optional_str("bmkUri", b, &mut validity);
        let url = match self.maybe_store_href(url) {
            Ok(u) => (Some(u.into_string())),
            Err(e) => {
                log::warn!("Incoming bookmark has an invalid URL: {:?}", e);
                // The bookmark has an invalid URL, so we can't apply it.
                set_replace(&mut validity);
                None
            }
        };

        self.db.execute_named_cached(
            r#"REPLACE INTO moz_bookmarks_synced(guid, parentGuid, serverModified, needsMerge, kind,
                                                 dateAdded, title, keyword, validity, placeId)
               VALUES(:guid, :parentGuid, :serverModified, 1, :kind,
                      :dateAdded, NULLIF(:title, ""), :keyword, :validity,
                      CASE WHEN :url ISNULL
                      THEN NULL
                      ELSE (SELECT id FROM moz_places
                            WHERE url_hash = hash(:url) AND
                            url = :url)
                      END
                      )"#,
            &[
                (":guid", &record_id.as_guid().as_str()),
                (
                    ":parentGuid",
                    &parent_record_id.as_ref().map(BookmarkRecordId::as_guid),
                ),
                (":serverModified", &(modified.as_millis() as i64)),
                (":kind", &SyncedBookmarkKind::Bookmark),
                (":dateAdded", &date_added),
                (":title", &maybe_truncate_title(&title)),
                (":keyword", &keyword),
                (":validity", &validity),
                (":url", &url),
            ],
        )?;
        for t in tags {
            self.db.execute_named_cached(
                "INSERT OR IGNORE INTO moz_tags(tag, lastModified)
                 VALUES(:tag, now())",
                &[(":tag", &t)],
            )?;
            self.db.execute_named_cached(
                "INSERT INTO moz_bookmarks_synced_tag_relation(itemId, tagId)
                 VALUES((SELECT id FROM moz_bookmarks_synced
                         WHERE guid = :guid),
                        (SELECT id FROM moz_tags
                         WHERE tag = :tag))",
                &[(":guid", &record_id.as_guid().as_str()), (":tag", &t)],
            )?;
        }
        Ok(())
    }

    fn store_incoming_folder(&self, modified: ServerTimestamp, f: &JsonValue) -> Result<()> {
        let mut validity = SyncedBookmarkValidity::Valid;

        let record_id = unpack_id("id", f)?;
        let parent_record_id = unpack_optional_id("parentid", f);
        let date_added = unpack_optional_i64("dateAdded", f, &mut validity);
        let title = unpack_optional_str("title", f, &mut validity);

        let children = if let Some(array) = f["children"].as_array() {
            let mut children = Vec::with_capacity(array.len());
            for v in array {
                if v.is_string() {
                    children.push(BookmarkRecordId::from_payload_id(
                        v.as_str().unwrap().into(),
                    ));
                } else {
                    return Err(
                        ErrorKind::InvalidPlaceInfo(InvalidPlaceInfo::InvalidChildGuid).into(),
                    );
                }
            }
            children
        } else {
            vec![]
        };

        self.db.execute_named_cached(
            r#"REPLACE INTO moz_bookmarks_synced(guid, parentGuid, serverModified, needsMerge, kind,
                                                 dateAdded, title)
               VALUES(:guid, :parentGuid, :serverModified, 1, :kind,
                      :dateAdded, NULLIF(:title, ""))"#,
            &[
                (":guid", &record_id.as_guid().as_str()),
                (
                    ":parentGuid",
                    &parent_record_id.as_ref().map(BookmarkRecordId::as_guid),
                ),
                (":serverModified", &(modified.as_millis() as i64)),
                (":kind", &SyncedBookmarkKind::Folder),
                (":dateAdded", &date_added),
                (":title", &maybe_truncate_title(&title)),
            ],
        )?;
        sql_support::each_sized_chunk(
            &children,
            // -1 because we want to leave an extra binding parameter (`?1`)
            // for the folder's GUID.
            sql_support::default_max_variable_number() - 1,
            |chunk, offset| -> Result<()> {
                let sql = format!(
                    "INSERT INTO moz_bookmarks_synced_structure(guid, parentGuid, position)
                     VALUES {}",
                    // Builds a fragment like `(?2, ?1, 0), (?3, ?1, 1), ...`,
                    // where ?1 is the folder's GUID, [?2, ?3] are the first and
                    // second child GUIDs (SQLite binding parameters index
                    // from 1), and [0, 1] are the positions. This lets us store
                    // the folder's children using as few statements as
                    // possible.
                    sql_support::repeat_display(chunk.len(), ",", |index, f| {
                        // Each child's position is its index in `f.children`;
                        // that is, the `offset` of the current chunk, plus the
                        // child's `index` within the chunk.
                        let position = offset + index;
                        write!(f, "(?{}, ?1, {})", index + 2, position)
                    })
                );
                self.db.execute(
                    &sql,
                    iter::once(&record_id)
                        .chain(chunk.iter())
                        .map(|id| id.as_guid().as_str()),
                )?;
                Ok(())
            },
        )?;
        Ok(())
    }

    fn store_incoming_tombstone(&self, modified: ServerTimestamp, guid: &SyncGuid) -> Result<()> {
        self.db.execute_named_cached(
            "REPLACE INTO moz_bookmarks_synced(guid, parentGuid, serverModified, needsMerge,
                                               dateAdded, isDeleted)
             VALUES(:guid, NULL, :serverModified, 1, 0, 1)",
            &[
                (":guid", guid),
                (":serverModified", &(modified.as_millis() as i64)),
            ],
        )?;
        Ok(())
    }

    fn maybe_rewrite_and_store_query_url(
        &self,
        tag_folder_name: Option<&str>,
        record_id: &BookmarkRecordId,
        url: Url,
        validity: &mut SyncedBookmarkValidity,
    ) -> Result<Option<Url>> {
        // wow - this  is complex, but markh is struggling to see how to
        // improve it
        let maybe_url = {
            // If the URL has `type={RESULTS_AS_TAG_CONTENTS}` then we
            // rewrite the URL as `place:tag=...`
            // Sadly we can't use `url.query_pairs()` here as the format of
            // the url is, eg, `place:type=7` - ie, the "params" are actually
            // the path portion of the URL.
            let parse = url::form_urlencoded::parse(&url.path().as_bytes());
            if parse
                .clone()
                .any(|(k, v)| k == "type" && v == RESULTS_AS_TAG_CONTENTS)
            {
                if let Some(t) = tag_folder_name {
                    validate_tag(t)
                        .ensure_valid()
                        .and_then(|tag| Ok(Url::parse(&format!("place:tag={}", tag))?))
                        .map(|url| {
                            set_reupload(validity);
                            Some(url)
                        })
                        .unwrap_or_else(|_| {
                            set_replace(validity);
                            None
                        })
                } else {
                    set_replace(validity);
                    None
                }
            } else {
                // If we have `folder=...` the folder value is a row_id
                // from desktop, so useless to us - so we append `&excludeItems=1`
                // if it isn't already there.
                if parse.clone().any(|(k, _)| k == "folder") {
                    if parse.clone().any(|(k, v)| k == "excludeItems" && v == "1") {
                        Some(url)
                    } else {
                        // need to add excludeItems, and I guess we should do
                        // it properly without resorting to string manipulation...
                        let tail = url::form_urlencoded::Serializer::new(String::new())
                            .extend_pairs(parse.clone())
                            .append_pair("excludeItems", "1")
                            .finish();
                        set_reupload(validity);
                        Some(Url::parse(&format!("place:{}", tail))?)
                    }
                } else {
                    // it appears to be fine!
                    Some(url)
                }
            }
        };
        Ok(match self.maybe_store_url(maybe_url) {
            Ok(url) => Some(url),
            Err(e) => {
                log::warn!("query {} has invalid URL: {:?}", record_id.as_guid(), e);
                set_replace(validity);
                None
            }
        })
    }

    fn store_incoming_query(&self, modified: ServerTimestamp, q: &JsonValue) -> Result<()> {
        let mut validity = SyncedBookmarkValidity::Valid;

        let record_id = unpack_id("id", q)?;
        let parent_record_id = unpack_optional_id("parentid", q);
        let date_added = unpack_optional_i64("dateAdded", q, &mut validity);
        let title = unpack_optional_str("title", q, &mut validity);
        let url = unpack_optional_str("bmkUri", q, &mut validity);
        let tag_folder_name = unpack_optional_str("folderName", q, &mut validity);

        let url = match url.and_then(|href| Url::parse(href).ok()) {
            Some(url) => self.maybe_rewrite_and_store_query_url(
                tag_folder_name,
                &record_id,
                url,
                &mut validity,
            )?,
            None => {
                log::warn!("query {} has invalid URL", &record_id.as_guid(),);
                set_replace(&mut validity);
                None
            }
        };

        self.db.execute_named_cached(
            r#"REPLACE INTO moz_bookmarks_synced(guid, parentGuid, serverModified, needsMerge, kind,
                                                 dateAdded, title, validity, placeId)
               VALUES(:guid, :parentGuid, :serverModified, 1, :kind,
                      :dateAdded, NULLIF(:title, ""), :validity,
                      (SELECT id FROM moz_places
                            WHERE url_hash = hash(:url) AND
                            url = :url
                      )
                     )"#,
            &[
                (":guid", &record_id.as_guid().as_str()),
                (
                    ":parentGuid",
                    &parent_record_id.as_ref().map(BookmarkRecordId::as_guid),
                ),
                (":serverModified", &(modified.as_millis() as i64)),
                (":kind", &SyncedBookmarkKind::Query),
                (":dateAdded", &date_added),
                (":title", &maybe_truncate_title(&title)),
                (":validity", &validity),
                (":url", &url.map(Url::into_string)),
            ],
        )?;
        Ok(())
    }

    fn store_incoming_livemark(&self, modified: ServerTimestamp, l: &JsonValue) -> Result<()> {
        let mut validity = SyncedBookmarkValidity::Valid;

        let record_id = unpack_id("id", l)?;
        let parent_record_id = unpack_optional_id("parentid", l);
        let date_added = unpack_optional_i64("dateAdded", l, &mut validity);
        let title = unpack_optional_str("title", l, &mut validity);
        let feed_url = unpack_optional_str("feedUri", l, &mut validity);
        let site_url = unpack_optional_str("siteUri", l, &mut validity);

        // livemarks don't store a reference to the place, so we validate it manually.
        fn validate_href(h: Option<&str>, guid: &SyncGuid, what: &str) -> Option<String> {
            match h {
                Some(h) => match Url::parse(&h) {
                    Ok(url) => {
                        let s = url.to_string();
                        if s.len() > URL_LENGTH_MAX {
                            log::warn!("Livemark {} has a {} URL which is too long", &guid, what);
                            None
                        } else {
                            Some(s)
                        }
                    }
                    Err(e) => {
                        log::warn!("Livemark {} has an invalid {} URL: {:?}", &guid, what, e);
                        None
                    }
                },
                None => {
                    log::warn!("Livemark {} has no {} URL", &guid, what);
                    None
                }
            }
        }
        let feed_url = validate_href(feed_url, &record_id.as_guid(), "feed");
        let site_url = validate_href(site_url, &record_id.as_guid(), "site");

        if feed_url.is_none() {
            set_replace(&mut validity);
        }

        self.db.execute_named_cached(
            "REPLACE INTO moz_bookmarks_synced(guid, parentGuid, serverModified, needsMerge, kind,
                                               dateAdded, title, feedURL, siteURL, validity)
             VALUES(:guid, :parentGuid, :serverModified, 1, :kind,
                    :dateAdded, :title, :feedUrl, :siteUrl, :validity)",
            &[
                (":guid", &record_id.as_guid().as_str()),
                (
                    ":parentGuid",
                    &parent_record_id.as_ref().map(BookmarkRecordId::as_guid),
                ),
                (":serverModified", &(modified.as_millis() as i64)),
                (":kind", &SyncedBookmarkKind::Livemark),
                (":dateAdded", &date_added),
                (":title", &title),
                (":feedUrl", &feed_url),
                (":siteUrl", &site_url),
                (":validity", &validity),
            ],
        )?;
        Ok(())
    }

    fn store_incoming_sep(&self, modified: ServerTimestamp, s: &JsonValue) -> Result<()> {
        let mut validity = SyncedBookmarkValidity::Valid;

        let record_id = unpack_id("id", s)?;
        let parent_record_id = unpack_optional_id("parentid", s);
        let date_added = unpack_optional_i64("dateAdded", s, &mut validity);

        self.db.execute_named_cached(
            "REPLACE INTO moz_bookmarks_synced(guid, parentGuid, serverModified, needsMerge, kind,
                                               dateAdded)
             VALUES(:guid, :parentGuid, :serverModified, 1, :kind,
                    :dateAdded)",
            &[
                (":guid", &record_id.as_guid().as_str()),
                (
                    ":parentGuid",
                    &parent_record_id.as_ref().map(BookmarkRecordId::as_guid),
                ),
                (":serverModified", &(modified.as_millis() as i64)),
                (":kind", &SyncedBookmarkKind::Separator),
                (":dateAdded", &date_added),
            ],
        )?;
        Ok(())
    }

    fn maybe_store_href(&self, href: Option<&str>) -> Result<Url> {
        if let Some(href) = href {
            self.maybe_store_url(Some(Url::parse(href)?))
        } else {
            self.maybe_store_url(None)
        }
    }

    fn maybe_store_url(&self, url: Option<Url>) -> Result<Url> {
        if let Some(url) = url {
            if url.as_str().len() > URL_LENGTH_MAX {
                return Err(ErrorKind::InvalidPlaceInfo(InvalidPlaceInfo::UrlTooLong).into());
            }
            self.db.execute_named_cached(
                "INSERT OR IGNORE INTO moz_places(guid, url, url_hash, frecency)
                 VALUES(IFNULL((SELECT guid FROM moz_places
                                WHERE url_hash = hash(:url) AND
                                      url = :url),
                        generate_guid()), :url, hash(:url),
                        (CASE substr(:url, 1, 6) WHEN 'place:' THEN 0 ELSE -1 END))",
                &[(":url", &url.as_str())],
            )?;
            Ok(url)
        } else {
            Err(ErrorKind::InvalidPlaceInfo(InvalidPlaceInfo::NoUrl).into())
        }
    }
}

fn unpack_id(key: &str, data: &JsonValue) -> Result<BookmarkRecordId> {
    if let Some(id) = data[key].as_str() {
        Ok(BookmarkRecordId::from_payload_id(id.into()))
    } else {
        Err(ErrorKind::InvalidPlaceInfo(InvalidPlaceInfo::InvalidGuid).into())
    }
}

fn unpack_optional_id(key: &str, data: &JsonValue) -> Option<BookmarkRecordId> {
    let val = &data[key];
    val.as_str()
        .map(|v| BookmarkRecordId::from_payload_id(v.into()))
}

fn unpack_optional_str<'a>(
    key: &str,
    data: &'a JsonValue,
    validity: &mut SyncedBookmarkValidity,
) -> Option<&'a str> {
    let val = &data[key];
    match val {
        JsonValue::String(s) => Some(&s),
        JsonValue::Null => None,
        _ => {
            set_reupload(validity);
            None
        }
    }
}

fn unpack_optional_i64(
    key: &str,
    data: &JsonValue,
    validity: &mut SyncedBookmarkValidity,
) -> Option<i64> {
    let val = &data[key];
    if val.is_i64() {
        val.as_i64()
    } else if val.is_u64() {
        Some(val.as_u64().unwrap() as i64)
    } else if val.is_string() {
        set_reupload(validity);
        if let Ok(n) = val.as_str().unwrap().parse() {
            Some(n)
        } else {
            None
        }
    } else if val.is_null() {
        None
    } else {
        set_reupload(validity);
        None
    }
}

fn set_replace(validity: &mut SyncedBookmarkValidity) {
    if *validity < SyncedBookmarkValidity::Replace {
        *validity = SyncedBookmarkValidity::Replace;
    }
}

fn set_reupload(validity: &mut SyncedBookmarkValidity) {
    if *validity < SyncedBookmarkValidity::Reupload {
        *validity = SyncedBookmarkValidity::Reupload;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::places_api::{test::new_mem_api, PlacesApi, SyncConn};
    use crate::storage::bookmarks::BookmarkRootGuid;

    use crate::bookmark_sync::record::{BookmarkItemRecord, FolderRecord};
    use crate::bookmark_sync::tests::SyncedBookmarkItem;
    use pretty_assertions::assert_eq;
    use serde_json::{json, Value};
    use sync15::Payload;

    fn apply_incoming(api: &PlacesApi, records_json: Value) -> SyncConn<'_> {
        let conn = api.open_sync_connection().expect("should get a connection");

        let server_timestamp = ServerTimestamp(0);
        let applicator = IncomingApplicator::new(&conn);

        match records_json {
            Value::Array(records) => {
                for record in records {
                    let payload = Payload::from_json(record).unwrap();
                    applicator
                        .apply_payload(payload, server_timestamp)
                        .expect("Should apply incoming and stage outgoing records");
                }
            }
            Value::Object(_) => {
                let payload = Payload::from_json(records_json).unwrap();
                applicator
                    .apply_payload(payload, server_timestamp)
                    .expect("Should apply incoming and stage outgoing records");
            }
            _ => panic!("unexpected json value"),
        }

        conn
    }

    fn assert_incoming_creates_mirror_item(record_json: Value, expected: &SyncedBookmarkItem) {
        let guid = record_json["id"]
            .as_str()
            .expect("id must be a string")
            .to_string();
        let api = new_mem_api();
        let conn = apply_incoming(&api, record_json);
        let got = SyncedBookmarkItem::get(&conn, &guid.into())
            .expect("should work")
            .expect("item should exist");
        assert_eq!(*expected, got);
    }

    #[test]
    fn test_apply_bookmark() {
        assert_incoming_creates_mirror_item(
            json!({
                "id": "bookmarkAAAA",
                "type": "bookmark",
                "parentid": "unfiled",
                "parentName": "unfiled",
                "dateAdded": 1_381_542_355_843u64,
                "title": "A",
                "bmkUri": "http://example.com/a",
                "tags": ["foo", "bar"],
                "keyword": "baz",
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Valid)
                .kind(SyncedBookmarkKind::Bookmark)
                .parent_guid(Some(&BookmarkRootGuid::Unfiled.as_guid()))
                .title(Some("A"))
                .url(Some("http://example.com/a"))
                .tags(vec!["foo".into(), "bar".into()])
                .keyword(Some("baz")),
        );
    }

    #[test]
    fn test_apply_folder() {
        let children = (1..sql_support::default_max_variable_number() * 2)
            .map(|i| SyncGuid::from(format!("{:A>12}", i)))
            .collect::<Vec<_>>();
        let value = serde_json::to_value(BookmarkItemRecord::from(FolderRecord {
            record_id: BookmarkRecordId::from_payload_id("folderAAAAAA".into()),
            parent_record_id: Some(BookmarkRecordId::from_payload_id("unfiled".into())),
            parent_title: Some("unfiled".into()),
            date_added: Some(0),
            has_dupe: true,
            title: Some("A".into()),
            children: children
                .iter()
                .map(|guid| BookmarkRecordId::from(guid.clone()))
                .collect(),
        }))
        .expect("Should serialize folder with children");
        assert_incoming_creates_mirror_item(
            value,
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Valid)
                .kind(SyncedBookmarkKind::Folder)
                .parent_guid(Some(&BookmarkRootGuid::Unfiled.as_guid()))
                .title(Some("A"))
                .children(children),
        );
    }

    #[test]
    fn test_apply_tombstone() {
        assert_incoming_creates_mirror_item(
            json!({
                "id": "deadbeef____",
                "deleted": true
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Valid)
                .deleted(true),
        );
    }

    #[test]
    fn test_apply_query() {
        // First check that various inputs result in the expected records in
        // the mirror table.

        // A valid query (which actually looks just like a bookmark, but that's ok)
        assert_incoming_creates_mirror_item(
            json!({
                "id": "query1______",
                "type": "query",
                "parentid": "unfiled",
                "parentName": "Unfiled Bookmarks",
                "dateAdded": 1_381_542_355_843u64,
                "title": "Some query",
                "bmkUri": "place:tag=foo",
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Valid)
                .kind(SyncedBookmarkKind::Query)
                .parent_guid(Some(&BookmarkRootGuid::Unfiled.as_guid()))
                .title(Some("Some query"))
                .url(Some("place:tag=foo")),
        );

        // A query with an old "type=" param and a valid folderName. Should
        // get Reupload due to rewriting the URL.
        assert_incoming_creates_mirror_item(
            json!({
                "id": "query1______",
                "type": "query",
                "parentid": "unfiled",
                "bmkUri": "place:type=7",
                "folderName": "a-folder-name",
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Reupload)
                .kind(SyncedBookmarkKind::Query)
                .url(Some("place:tag=a-folder-name")),
        );

        // A query with an old "type=" param and an invalid folderName. Should
        // get replaced with an empty URL
        assert_incoming_creates_mirror_item(
            json!({
                "id": "query1______",
                "type": "query",
                "parentid": "unfiled",
                "bmkUri": "place:type=7",
                "folderName": "",
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Replace)
                .kind(SyncedBookmarkKind::Query)
                .url(None),
        );

        // A query with an old "folder=" but no excludeItems - should be
        // marked as Reupload due to the URL being rewritten.
        assert_incoming_creates_mirror_item(
            json!({
                "id": "query1______",
                "type": "query",
                "parentid": "unfiled",
                "bmkUri": "place:folder=123",
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Reupload)
                .kind(SyncedBookmarkKind::Query)
                .url(Some("place:folder=123&excludeItems=1")),
        );

        // A query with an old "folder=" and already with  excludeItems -
        // should be marked as Valid
        assert_incoming_creates_mirror_item(
            json!({
                "id": "query1______",
                "type": "query",
                "parentid": "unfiled",
                "bmkUri": "place:folder=123&excludeItems=1",
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Valid)
                .kind(SyncedBookmarkKind::Query)
                .url(Some("place:folder=123&excludeItems=1")),
        );

        // A query with a URL that can't be parsed.
        assert_incoming_creates_mirror_item(
            json!({
                "id": "query1______",
                "type": "query",
                "parentid": "unfiled",
                "bmkUri": "foo",
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Replace)
                .kind(SyncedBookmarkKind::Query)
                .url(None),
        );

        // With a missing URL
        assert_incoming_creates_mirror_item(
            json!({
                "id": "query1______",
                "type": "query",
                "parentid": "unfiled",
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Replace)
                .kind(SyncedBookmarkKind::Query)
                .url(None),
        );
    }

    #[test]
    fn test_apply_sep() {
        // Separators don't have much variation.
        assert_incoming_creates_mirror_item(
            json!({
                "id": "sep1________",
                "type": "separator",
                "parentid": "unfiled",
                "parentName": "Unfiled Bookmarks",
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Valid)
                .kind(SyncedBookmarkKind::Separator)
                .parent_guid(Some(&BookmarkRootGuid::Unfiled.as_guid()))
                .needs_merge(true),
        );
    }

    #[test]
    fn test_apply_livemark() {
        // A livemark with missing URLs
        assert_incoming_creates_mirror_item(
            json!({
                "id": "livemark1___",
                "type": "livemark",
                "parentid": "unfiled",
                "parentName": "Unfiled Bookmarks",
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Replace)
                .kind(SyncedBookmarkKind::Livemark)
                .parent_guid(Some(&BookmarkRootGuid::Unfiled.as_guid()))
                .needs_merge(true)
                .feed_url(None)
                .site_url(None),
        );
        // Valid feed_url but invalid site_url is considered "valid", but the
        // invalid URL is dropped.
        assert_incoming_creates_mirror_item(
            json!({
                "id": "livemark1___",
                "type": "livemark",
                "parentid": "unfiled",
                "parentName": "Unfiled Bookmarks",
                "feedUri": "http://example.com",
                "siteUri": "foo"
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Valid)
                .kind(SyncedBookmarkKind::Livemark)
                .parent_guid(Some(&BookmarkRootGuid::Unfiled.as_guid()))
                .needs_merge(true)
                .feed_url(Some("http://example.com/"))
                .site_url(None),
        );
        // Everything valid
        assert_incoming_creates_mirror_item(
            json!({
                "id": "livemark1___",
                "type": "livemark",
                "parentid": "unfiled",
                "parentName": "Unfiled Bookmarks",
                "feedUri": "http://example.com",
                "siteUri": "http://example.com/something"
            }),
            &SyncedBookmarkItem::new()
                .validity(SyncedBookmarkValidity::Valid)
                .kind(SyncedBookmarkKind::Livemark)
                .parent_guid(Some(&BookmarkRootGuid::Unfiled.as_guid()))
                .needs_merge(true)
                .feed_url(Some("http://example.com/"))
                .site_url(Some("http://example.com/something")),
        );
    }

    #[test]
    fn test_apply_unknown() {
        let api = new_mem_api();
        let conn = api.open_sync_connection().expect("should get a connection");
        let applicator = IncomingApplicator::new(&conn);

        let record = json!({
            "id": "unknownAAAA",
            "type": "fancy",
        });
        let payload = Payload::from_json(record).unwrap();
        match applicator
            .apply_payload(payload, ServerTimestamp(0))
            .expect_err("Should not apply record with unknown type")
            .kind()
        {
            ErrorKind::UnsupportedIncomingBookmarkType(t) => {
                assert_eq!(t.as_str().unwrap(), "fancy")
            }
            kind => panic!("Wrong error kind for unknown type: {:?}", kind),
        }
    }
}
