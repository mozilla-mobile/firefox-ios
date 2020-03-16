/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use std::fmt;

use crate::storage::bookmarks::BookmarkRootGuid;
use serde::{
    de::{Deserialize, Deserializer, Visitor},
    ser::{Serialize, Serializer},
};
use serde_derive::*;
use sync_guid::Guid as SyncGuid;

/// A bookmark record ID. Bookmark record IDs are the same as Places GUIDs,
/// except for:
///
/// 1. The Places root, which is "places". Note that the Places root is not
///    synced, but is still referenced in the user content roots' `parentid`s.
/// 2. The four user content roots, which omit trailing underscores.
///
/// This wrapper helps avoid mix-ups like storing a record ID instead of a GUID,
/// or uploading a GUID instead of a record ID.
///
/// Internally, we convert record IDs to GUIDs when applying incoming records,
/// and only convert back to GUIDs during upload.
#[derive(Clone, Debug, Hash, PartialEq)]
pub struct BookmarkRecordId(SyncGuid);

impl BookmarkRecordId {
    /// Creates a bookmark record ID from a Sync record payload ID.
    pub fn from_payload_id(payload_id: SyncGuid) -> BookmarkRecordId {
        BookmarkRecordId(match payload_id.as_str() {
            "places" => BookmarkRootGuid::Root.as_guid(),
            "menu" => BookmarkRootGuid::Menu.as_guid(),
            "toolbar" => BookmarkRootGuid::Toolbar.as_guid(),
            "unfiled" => BookmarkRootGuid::Unfiled.as_guid(),
            "mobile" => BookmarkRootGuid::Mobile.as_guid(),
            _ => payload_id,
        })
    }

    /// Returns a reference to the record payload ID. This is the borrowed
    /// version of `into_payload_id`, and used for serialization.
    #[inline]
    pub fn as_payload_id(&self) -> &str {
        self.root_payload_id().unwrap_or_else(|| self.0.as_ref())
    }

    /// Returns the record payload ID. This is the owned version of
    /// `as_payload_id`, and exists to avoid copying strings when uploading
    /// tombstones.
    #[inline]
    pub fn into_payload_id(self) -> String {
        self.root_payload_id()
            .map(Into::into)
            .unwrap_or_else(|| (self.0).into_string())
    }

    /// Returns a reference to the GUID for this record ID.
    #[inline]
    pub fn as_guid(&self) -> &SyncGuid {
        &self.0
    }

    fn root_payload_id(&self) -> Option<&str> {
        Some(match BookmarkRootGuid::from_guid(self.as_guid()) {
            Some(BookmarkRootGuid::Root) => "places",
            Some(BookmarkRootGuid::Menu) => "menu",
            Some(BookmarkRootGuid::Toolbar) => "toolbar",
            Some(BookmarkRootGuid::Unfiled) => "unfiled",
            Some(BookmarkRootGuid::Mobile) => "mobile",
            None => return None,
        })
    }
}

/// Converts a Places GUID into a bookmark record ID.
impl From<SyncGuid> for BookmarkRecordId {
    #[inline]
    fn from(guid: SyncGuid) -> BookmarkRecordId {
        BookmarkRecordId(guid)
    }
}

/// Converts a bookmark record ID into a Places GUID.
impl From<BookmarkRecordId> for SyncGuid {
    #[inline]
    fn from(record_id: BookmarkRecordId) -> SyncGuid {
        record_id.0
    }
}

impl Serialize for BookmarkRecordId {
    #[inline]
    fn serialize<S: Serializer>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error> {
        serializer.serialize_str(self.as_payload_id())
    }
}

impl<'de> Deserialize<'de> for BookmarkRecordId {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> std::result::Result<Self, D::Error> {
        struct V;

        impl<'de> Visitor<'de> for V {
            type Value = BookmarkRecordId;

            fn expecting(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                f.write_str("a bookmark record ID")
            }

            #[inline]
            fn visit_string<E: serde::de::Error>(
                self,
                payload_id: String,
            ) -> std::result::Result<BookmarkRecordId, E> {
                // The JSON deserializer passes owned strings, so we can avoid
                // cloning the payload ID in the common case...
                Ok(BookmarkRecordId::from_payload_id(payload_id.into()))
            }

            #[inline]
            fn visit_str<E: serde::de::Error>(
                self,
                payload_id: &str,
            ) -> std::result::Result<BookmarkRecordId, E> {
                // ...However, the Serde docs say we must implement
                // `visit_str` if we implement `visit_string`, so we also
                // provide an implementation that clones the ID.
                Ok(BookmarkRecordId::from_payload_id(payload_id.into()))
            }
        }

        deserializer.deserialize_string(V)
    }
}

#[derive(Clone, Debug, Deserialize, Hash, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BookmarkRecord {
    // Note that `SyncGuid` does not check for validity, which is what we
    // want. If the bookmark has an invalid GUID, we'll make a new one.
    #[serde(rename = "id")]
    pub record_id: BookmarkRecordId,

    #[serde(rename = "parentid")]
    pub parent_record_id: Option<BookmarkRecordId>,

    #[serde(rename = "parentName", skip_serializing_if = "Option::is_none")]
    pub parent_title: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(default, deserialize_with = "de_maybe_stringified_timestamp")]
    pub date_added: Option<i64>,

    #[serde(default)]
    pub has_dupe: bool,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,

    #[serde(rename = "bmkUri", skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub keyword: Option<String>,

    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub tags: Vec<String>,
}

impl From<BookmarkRecord> for BookmarkItemRecord {
    #[inline]
    fn from(b: BookmarkRecord) -> BookmarkItemRecord {
        BookmarkItemRecord::Bookmark(b)
    }
}

#[derive(Clone, Debug, Deserialize, Hash, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct QueryRecord {
    #[serde(rename = "id")]
    pub record_id: BookmarkRecordId,

    #[serde(rename = "parentid")]
    pub parent_record_id: Option<BookmarkRecordId>,

    #[serde(rename = "parentName", skip_serializing_if = "Option::is_none")]
    pub parent_title: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(default, deserialize_with = "de_maybe_stringified_timestamp")]
    pub date_added: Option<i64>,

    #[serde(default)]
    pub has_dupe: bool,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,

    #[serde(rename = "bmkUri", skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,

    #[serde(rename = "folderName", skip_serializing_if = "Option::is_none")]
    pub tag_folder_name: Option<String>,
}

impl From<QueryRecord> for BookmarkItemRecord {
    #[inline]
    fn from(q: QueryRecord) -> BookmarkItemRecord {
        BookmarkItemRecord::Query(q)
    }
}

#[derive(Clone, Debug, Deserialize, Hash, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FolderRecord {
    #[serde(rename = "id")]
    pub record_id: BookmarkRecordId,

    #[serde(rename = "parentid")]
    pub parent_record_id: Option<BookmarkRecordId>,

    #[serde(rename = "parentName", skip_serializing_if = "Option::is_none")]
    pub parent_title: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(default, deserialize_with = "de_maybe_stringified_timestamp")]
    pub date_added: Option<i64>,

    #[serde(default)]
    pub has_dupe: bool,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,

    #[serde(default)]
    pub children: Vec<BookmarkRecordId>,
}

impl From<FolderRecord> for BookmarkItemRecord {
    #[inline]
    fn from(f: FolderRecord) -> BookmarkItemRecord {
        BookmarkItemRecord::Folder(f)
    }
}

#[derive(Clone, Debug, Deserialize, Hash, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct LivemarkRecord {
    #[serde(rename = "id")]
    pub record_id: BookmarkRecordId,

    #[serde(rename = "parentid")]
    pub parent_record_id: Option<BookmarkRecordId>,

    #[serde(rename = "parentName", skip_serializing_if = "Option::is_none")]
    pub parent_title: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(default, deserialize_with = "de_maybe_stringified_timestamp")]
    pub date_added: Option<i64>,

    #[serde(default)]
    pub has_dupe: bool,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,

    #[serde(rename = "feedUri", skip_serializing_if = "Option::is_none")]
    pub feed_url: Option<String>,

    #[serde(rename = "siteUri", skip_serializing_if = "Option::is_none")]
    pub site_url: Option<String>,
}

impl From<LivemarkRecord> for BookmarkItemRecord {
    #[inline]
    fn from(l: LivemarkRecord) -> BookmarkItemRecord {
        BookmarkItemRecord::Livemark(l)
    }
}

#[derive(Clone, Debug, Deserialize, Hash, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SeparatorRecord {
    #[serde(rename = "id")]
    pub record_id: BookmarkRecordId,

    #[serde(rename = "parentid")]
    pub parent_record_id: Option<BookmarkRecordId>,

    #[serde(rename = "parentName", skip_serializing_if = "Option::is_none")]
    pub parent_title: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(default, deserialize_with = "de_maybe_stringified_timestamp")]
    pub date_added: Option<i64>,

    #[serde(default)]
    pub has_dupe: bool,

    // Not used on newer clients, but can be used to detect parent-child
    // position disagreements. Older clients use this for deduping.
    #[serde(rename = "pos", skip_serializing_if = "Option::is_none")]
    pub position: Option<i64>,
}

impl From<SeparatorRecord> for BookmarkItemRecord {
    #[inline]
    fn from(s: SeparatorRecord) -> BookmarkItemRecord {
        BookmarkItemRecord::Separator(s)
    }
}

#[derive(Clone, Debug, Deserialize, Hash, PartialEq, Serialize)]
#[serde(tag = "type", rename_all = "camelCase")]
pub enum BookmarkItemRecord {
    Bookmark(BookmarkRecord),
    Query(QueryRecord),
    Folder(FolderRecord),
    Livemark(LivemarkRecord),
    Separator(SeparatorRecord),
}

// dateAdded on a bookmark might be a string! See #1148.
fn de_maybe_stringified_timestamp<'de, D>(
    deserializer: D,
) -> std::result::Result<Option<i64>, D::Error>
where
    D: serde::de::Deserializer<'de>,
{
    use std::marker::PhantomData;

    struct StringOrInt(PhantomData<Option<i64>>);

    impl<'de> Visitor<'de> for StringOrInt {
        type Value = Option<i64>;

        fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
            formatter.write_str("string or int")
        }

        fn visit_str<E>(self, value: &str) -> Result<Option<i64>, E>
        where
            E: serde::de::Error,
        {
            match value.parse::<i64>() {
                Ok(v) => Ok(Some(v)),
                Err(_) => Err(E::custom("invalid string literal")),
            }
        }

        // all positive int literals
        fn visit_i64<E: serde::de::Error>(self, value: i64) -> Result<Option<i64>, E> {
            Ok(Some(value.max(0)))
        }

        // all negative int literals
        fn visit_u64<E: serde::de::Error>(self, value: u64) -> Result<Option<i64>, E> {
            Ok(Some((value as i64).max(0)))
        }
    }
    deserializer.deserialize_any(StringOrInt(PhantomData))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::{json, Error};

    #[test]
    fn test_invalid_record_type() {
        let r: std::result::Result<BookmarkItemRecord, Error> =
            serde_json::from_value(json!({"id": "whatever", "type" : "unknown-type"}));
        let e = r.unwrap_err();
        assert!(e.is_data());
        // I guess is good enough to check we are hitting what we expect.
        assert!(e.to_string().contains("unknown-type"));
    }

    #[test]
    fn test_id_rewriting() {
        let j = json!({"id": "unfiled", "parentid": "menu", "type": "bookmark"});
        let r: BookmarkItemRecord = serde_json::from_value(j).expect("should deserialize");
        match &r {
            BookmarkItemRecord::Bookmark(b) => {
                assert_eq!(b.record_id.as_guid(), BookmarkRootGuid::Unfiled);
                assert_eq!(
                    b.parent_record_id.as_ref().map(BookmarkRecordId::as_guid),
                    Some(&BookmarkRootGuid::Menu.as_guid())
                );
            }
            _ => panic!("unexpected record type"),
        };
        let v = serde_json::to_value(r).expect("should serialize");
        assert_eq!(
            v,
            json!({
                "id": "unfiled",
                "parentid": "menu",
                "type": "bookmark",
                "hasDupe": false,
            })
        );

        let j = json!({"id": "unfiled", "parentid": "menu", "type": "query"});
        let r: BookmarkItemRecord = serde_json::from_value(j).expect("should deserialize");
        match &r {
            BookmarkItemRecord::Query(q) => {
                assert_eq!(q.record_id.as_guid(), BookmarkRootGuid::Unfiled);
                assert_eq!(
                    q.parent_record_id.as_ref().map(BookmarkRecordId::as_guid),
                    Some(&BookmarkRootGuid::Menu.as_guid())
                );
            }
            _ => panic!("unexpected record type"),
        };
        let v = serde_json::to_value(r).expect("should serialize");
        assert_eq!(
            v,
            json!({
                "id": "unfiled",
                "parentid": "menu",
                "type": "query",
                "hasDupe": false,
            })
        );

        let j = json!({"id": "unfiled", "parentid": "menu", "type": "folder"});
        let r: BookmarkItemRecord = serde_json::from_value(j).expect("should deserialize");
        match &r {
            BookmarkItemRecord::Folder(f) => {
                assert_eq!(f.record_id.as_guid(), BookmarkRootGuid::Unfiled);
                assert_eq!(
                    f.parent_record_id.as_ref().map(BookmarkRecordId::as_guid),
                    Some(&BookmarkRootGuid::Menu.as_guid())
                );
            }
            _ => panic!("unexpected record type"),
        };
        let v = serde_json::to_value(r).expect("should serialize");
        assert_eq!(
            v,
            json!({
                "id": "unfiled",
                "parentid": "menu",
                "type": "folder",
                "hasDupe": false,
                "children": [],
            })
        );

        let j = json!({"id": "unfiled", "parentid": "menu", "type": "livemark"});
        let r: BookmarkItemRecord = serde_json::from_value(j).expect("should deserialize");
        match &r {
            BookmarkItemRecord::Livemark(l) => {
                assert_eq!(l.record_id.as_guid(), BookmarkRootGuid::Unfiled);
                assert_eq!(
                    l.parent_record_id.as_ref().map(BookmarkRecordId::as_guid),
                    Some(&BookmarkRootGuid::Menu.as_guid())
                );
            }
            _ => panic!("unexpected record type"),
        };
        let v = serde_json::to_value(r).expect("should serialize");
        assert_eq!(
            v,
            json!({
                "id": "unfiled",
                "parentid": "menu",
                "type": "livemark",
                "hasDupe": false,
            })
        );

        let j = json!({"id": "unfiled", "parentid": "menu", "type": "separator"});
        let r: BookmarkItemRecord = serde_json::from_value(j).expect("should deserialize");
        match &r {
            BookmarkItemRecord::Separator(s) => {
                assert_eq!(s.record_id.as_guid(), BookmarkRootGuid::Unfiled);
                assert_eq!(
                    s.parent_record_id.as_ref().map(BookmarkRecordId::as_guid),
                    Some(&BookmarkRootGuid::Menu.as_guid())
                );
            }
            _ => panic!("unexpected record type"),
        };
        let v = serde_json::to_value(r).expect("should serialize");
        assert_eq!(
            v,
            json!({
                "id": "unfiled",
                "parentid": "menu",
                "type": "separator",
                "hasDupe": false,
            })
        );
    }

    // It's unfortunate that all below 'dateadded' tests only check the
    // 'BookmarkItemRecord' variant, so it would be a problem if `date_added` on
    // other variants forgot to do the `deserialize_with` dance. We could
    // implement a new type to make that less likely, but that's not foolproof
    // either and causes this hysterical raisin to leak out from this module.
    fn check_date_added(j: serde_json::Value, expected: Option<i64>) {
        let r: BookmarkItemRecord = serde_json::from_value(j).expect("should deserialize");
        match &r {
            BookmarkItemRecord::Bookmark(b) => assert_eq!(b.date_added, expected),
            _ => panic!("unexpected record type"),
        };
    }

    #[test]
    fn test_dateadded_missing() {
        check_date_added(
            json!({"id": "unfiled", "parentid": "menu", "type": "bookmark"}),
            None,
        )
    }

    #[test]
    fn test_dateadded_int() {
        check_date_added(
            json!({"id": "unfiled", "parentid": "menu", "type": "bookmark", "dateAdded": 123}),
            Some(123),
        )
    }

    #[test]
    fn test_dateadded_negative() {
        check_date_added(
            json!({"id": "unfiled", "parentid": "menu", "type": "bookmark", "dateAdded": -1}),
            Some(0),
        )
    }

    #[test]
    fn test_dateadded_str() {
        check_date_added(
            json!({"id": "unfiled", "parentid": "menu", "type": "bookmark", "dateAdded": "123"}),
            Some(123),
        )
    }

    // A kinda "policy" decision - like serde, 'type errors' fail rather than default.
    #[test]
    fn test_dateadded_null() {
        // a literal `null` is insane (and note we already test it *missing* above)
        serde_json::from_value::<BookmarkItemRecord>(
            json!({"id": "unfiled", "parentid": "menu", "type": "bookmark", "dateAdded": null}),
        )
        .expect_err("should fail, literal null");
    }

    #[test]
    fn test_dateadded_invalid_str() {
        serde_json::from_value::<BookmarkItemRecord>(
            json!({"id": "unfiled", "parentid": "menu", "type": "bookmark", "dateAdded": "foo"}),
        )
        .expect_err("should fail, bad string value");
    }

    #[test]
    fn test_dateadded_invalid_type() {
        serde_json::from_value::<BookmarkItemRecord>(
            json!({"id": "unfiled", "parentid": "menu", "type": "bookmark", "dateAdded": []}),
        )
        .expect_err("should fail, invalid type");
    }
}
