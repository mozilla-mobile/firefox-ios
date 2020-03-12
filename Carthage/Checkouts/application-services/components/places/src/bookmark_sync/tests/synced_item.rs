/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{
    bookmark_sync::{SyncedBookmarkKind, SyncedBookmarkValidity},
    db::PlacesDb,
    error::*,
    storage::RowId,
    types::Timestamp,
};
use rusqlite::Row;
use sync_guid::Guid as SyncGuid;

use sql_support::{self, ConnExt};
use sync15::ServerTimestamp;
use url::Url;

/// Our prod code never needs to read moz_bookmarks_synced, but our test code
/// does.
/// SyncedBookmarkValue is used in our struct so that we can do "smart"
/// comparisons - if an object created by tests has
/// SyncedBookmarkValue::Unspecified, we don't check the value against the
/// target of the comparison. We use this instead of Option<> so that we
/// can correctly check Option<> fields (ie, so that None isn't ambiguous
/// between "no value specified" and "value is exactly None"
#[derive(Clone, Debug)]
pub enum SyncedBookmarkValue<T> {
    Unspecified,
    Specified(T),
}

impl<T> Default for SyncedBookmarkValue<T> {
    fn default() -> Self {
        SyncedBookmarkValue::Unspecified
    }
}

impl<T> PartialEq for SyncedBookmarkValue<T>
where
    T: PartialEq,
{
    fn eq(&self, other: &SyncedBookmarkValue<T>) -> bool {
        match (self, other) {
            (SyncedBookmarkValue::Specified(s), SyncedBookmarkValue::Specified(o)) => s == o,
            _ => true,
        }
    }
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct SyncedBookmarkItem {
    pub id: SyncedBookmarkValue<RowId>,
    pub guid: SyncedBookmarkValue<SyncGuid>,
    pub parent_guid: SyncedBookmarkValue<Option<SyncGuid>>,
    pub server_modified: SyncedBookmarkValue<ServerTimestamp>,
    pub needs_merge: SyncedBookmarkValue<bool>,
    pub validity: SyncedBookmarkValue<SyncedBookmarkValidity>,
    pub deleted: SyncedBookmarkValue<bool>,
    pub kind: SyncedBookmarkValue<Option<SyncedBookmarkKind>>,
    pub date_added: SyncedBookmarkValue<Timestamp>,
    pub title: SyncedBookmarkValue<Option<String>>,
    pub place_id: SyncedBookmarkValue<Option<RowId>>,
    pub keyword: SyncedBookmarkValue<Option<String>>,
    pub description: SyncedBookmarkValue<Option<String>>,
    pub load_in_sidebar: SyncedBookmarkValue<Option<bool>>,
    pub smart_bookmark_name: SyncedBookmarkValue<Option<String>>,
    pub feed_url: SyncedBookmarkValue<Option<String>>,
    pub site_url: SyncedBookmarkValue<Option<String>>,
    // Note that url is *not* in the table, but a convenience for tests.
    pub url: SyncedBookmarkValue<Option<Url>>,
    pub tags: SyncedBookmarkValue<Vec<String>>,
    pub children: SyncedBookmarkValue<Vec<SyncGuid>>,
}

macro_rules! impl_builder_simple {
    ($builder_name:ident, $T:ty) => {
        pub fn $builder_name(&mut self, val: $T) -> &mut SyncedBookmarkItem {
            self.$builder_name = SyncedBookmarkValue::Specified(val);
            self
        }
    };
}
macro_rules! impl_builder_ref {
    ($builder_name:ident, $T:ty) => {
        pub fn $builder_name<'a>(&'a mut self, val: &$T) -> &'a mut SyncedBookmarkItem {
            self.$builder_name = SyncedBookmarkValue::Specified((*val).clone());
            self
        }
    };
}

macro_rules! impl_builder_opt_ref {
    ($builder_name:ident, $T:ty) => {
        pub fn $builder_name<'a>(&'a mut self, val: Option<&$T>) -> &'a mut SyncedBookmarkItem {
            self.$builder_name = SyncedBookmarkValue::Specified(val.map(Clone::clone));
            self
        }
    };
}

macro_rules! impl_builder_opt_string {
    ($builder_name:ident) => {
        pub fn $builder_name<'a>(&'a mut self, val: Option<&str>) -> &'a mut SyncedBookmarkItem {
            self.$builder_name = SyncedBookmarkValue::Specified(val.map(ToString::to_string));
            self
        }
    };
}

#[allow(unused)] // not all methods here are currently used.
impl SyncedBookmarkItem {
    // A "builder" pattern, so tests can do `SyncedBookmarkItem::new().title(...).url(...)` etc
    pub fn new() -> SyncedBookmarkItem {
        SyncedBookmarkItem {
            ..Default::default()
        }
    }

    impl_builder_simple!(id, RowId);
    impl_builder_ref!(guid, SyncGuid);
    impl_builder_opt_ref!(parent_guid, SyncGuid);
    impl_builder_simple!(server_modified, ServerTimestamp);
    impl_builder_simple!(needs_merge, bool);
    impl_builder_simple!(validity, SyncedBookmarkValidity);
    impl_builder_simple!(deleted, bool);

    // kind is a bit special because tombstones don't have one.
    pub fn kind(&mut self, kind: SyncedBookmarkKind) -> &mut SyncedBookmarkItem {
        self.kind = SyncedBookmarkValue::Specified(Some(kind));
        self
    }

    impl_builder_simple!(date_added, Timestamp);
    impl_builder_opt_string!(title);

    // no place_id - we use url instead.
    pub fn url<'a>(&'a mut self, url: Option<&str>) -> &'a mut SyncedBookmarkItem {
        let url = url.map(|s| Url::parse(s).expect("should be a valid url"));
        self.url = SyncedBookmarkValue::Specified(url);
        self
    }

    impl_builder_opt_string!(keyword);
    impl_builder_opt_string!(description);
    impl_builder_simple!(load_in_sidebar, Option<bool>);
    impl_builder_opt_string!(smart_bookmark_name);
    impl_builder_opt_string!(feed_url);
    impl_builder_opt_string!(site_url);

    pub fn tags<'a>(&'a mut self, mut tags: Vec<String>) -> &'a mut SyncedBookmarkItem {
        tags.sort();
        self.tags = SyncedBookmarkValue::Specified(tags);
        self
    }

    pub fn children(&mut self, children: Vec<SyncGuid>) -> &mut SyncedBookmarkItem {
        self.children = SyncedBookmarkValue::Specified(children);
        self
    }

    // Get a record from the DB.
    pub fn get(conn: &PlacesDb, guid: &SyncGuid) -> Result<Option<Self>> {
        Ok(conn.try_query_row(
            "SELECT b.*,
                    (SELECT p.url FROM moz_places p
                     WHERE p.id = b.placeId) AS url,
                    (SELECT group_concat(t.tag)
                     FROM moz_tags t
                     JOIN moz_bookmarks_synced_tag_relation r ON r.tagId = t.id
                     WHERE r.itemId = b.id) AS tags,
                    -- This creates a string like `1:bookmarkAAAA`
                    (SELECT group_concat(s.position || ':' || s.guid)
                     FROM moz_bookmarks_synced_structure s
                     WHERE s.parentGuid = b.guid) AS children
             FROM moz_bookmarks_synced b
             WHERE b.guid = :guid",
            &[(":guid", guid)],
            Self::from_row,
            true,
        )?)
    }

    // Return a new SyncedBookmarkItem from a database row. All values will
    // be SyncedBookmarkValue::Specified.
    fn from_row(row: &Row<'_>) -> Result<Self> {
        let mut tags = row
            .get::<_, Option<String>>("tags")?
            .map(|tags| {
                tags.split(',')
                    .map(ToString::to_string)
                    .collect::<Vec<String>>()
            })
            .unwrap_or_default();
        tags.sort();
        // SQLite's `group_concat` concatenates grouped rows in unspecified
        // order, so we prepend the position to the GUID in the query above,
        // then split and sort here. This trick is fairly inefficient, and
        // shouldn't be used in production code; see `BookmarksStore::{
        // stage_local_items_to_upload, fetch_outgoing_records}` for an example
        // of the latter. But it does let us collect children in a single
        // statement.
        let mut children: Vec<(i64, SyncGuid)> = row
            .get::<_, Option<String>>("children")?
            .map(|children| {
                children
                    .split(',')
                    .map(|t| {
                        let parts = t.splitn(2, ':').collect::<Vec<_>>();
                        (
                            parts[0].parse::<i64>().unwrap(),
                            SyncGuid::from(parts[1].to_owned()),
                        )
                    })
                    .collect::<Vec<_>>()
            })
            .unwrap_or_default();
        children.sort_by_key(|child| child.0);
        Ok(Self {
            id: SyncedBookmarkValue::Specified(row.get("id")?),
            guid: SyncedBookmarkValue::Specified(row.get("guid")?),
            parent_guid: SyncedBookmarkValue::Specified(row.get("parentGuid")?),
            server_modified: SyncedBookmarkValue::Specified(ServerTimestamp(
                row.get::<_, i64>("serverModified")?,
            )),
            needs_merge: SyncedBookmarkValue::Specified(row.get("needsMerge")?),
            validity: SyncedBookmarkValue::Specified(
                SyncedBookmarkValidity::from_u8(row.get("validity")?).expect("a valid validity"),
            ),
            deleted: SyncedBookmarkValue::Specified(row.get("isDeleted")?),
            kind: SyncedBookmarkValue::Specified(
                // tombstones have a kind of -1, so get it from the db as i8
                SyncedBookmarkKind::from_u8(row.get::<_, i8>("kind")? as u8).ok(),
            ),
            date_added: SyncedBookmarkValue::Specified(row.get("dateAdded")?),
            title: SyncedBookmarkValue::Specified(row.get("title")?),
            place_id: SyncedBookmarkValue::Specified(row.get("placeId")?),
            keyword: SyncedBookmarkValue::Specified(row.get("keyword")?),
            description: SyncedBookmarkValue::Specified(row.get("description")?),
            load_in_sidebar: SyncedBookmarkValue::Specified(row.get("loadInSidebar")?),
            smart_bookmark_name: SyncedBookmarkValue::Specified(row.get("smartBookmarkName")?),
            feed_url: SyncedBookmarkValue::Specified(row.get("feedUrl")?),
            site_url: SyncedBookmarkValue::Specified(row.get("siteUrl")?),
            url: SyncedBookmarkValue::Specified(
                row.get::<_, Option<String>>("url")?
                    .and_then(|s| Url::parse(&s).ok()),
            ),
            tags: SyncedBookmarkValue::Specified(tags),
            children: SyncedBookmarkValue::Specified(
                children.into_iter().map(|(_, guid)| guid).collect(),
            ),
        })
    }
}
