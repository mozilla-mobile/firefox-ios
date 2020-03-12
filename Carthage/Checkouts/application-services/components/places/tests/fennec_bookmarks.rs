/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use places::import::fennec::bookmarks::BookmarksMigrationResult;
use places::{api::places_api::PlacesApi, ErrorKind, Result, Timestamp};
use rusqlite::types::{ToSql, ToSqlOutput};
use rusqlite::{Connection, NO_PARAMS};
use std::path::Path;
use std::sync::atomic::{AtomicUsize, Ordering};
use sync_guid::Guid;
use tempfile::tempdir;

fn empty_fennec_db(path: &Path) -> Result<Connection> {
    let conn = Connection::open(path)?;
    conn.execute_batch(include_str!("./fennec_bookmarks_schema.sql"))?;
    Ok(conn)
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Ord, PartialOrd, Hash)]
#[repr(u8)]
pub enum FennecBookmarkType {
    Folder = 0,
    Bookmark = 1,
    Separator = 2,
}

impl ToSql for FennecBookmarkType {
    fn to_sql(&self) -> rusqlite::Result<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(*self as u8))
    }
}

#[derive(Clone, Debug)]
struct FennecBookmark {
    _id: i64,
    title: Option<String>,
    url: Option<String>,
    r#type: &'static FennecBookmarkType,
    parent: i64,
    position: i64,
    keyword: Option<String>,
    description: Option<String>,
    tags: Option<String>,
    favicon_id: Option<i64>,
    created: Option<Timestamp>,
    modified: Option<Timestamp>,
    guid: Guid,
    deleted: bool,
    local_version: i64,
    sync_version: i64,
}

impl FennecBookmark {
    fn insert_into_db(&self, conn: &Connection) -> Result<()> {
        let mut stmt = conn.prepare(&
            "INSERT OR IGNORE INTO bookmarks(_id, title, url, type, parent, position, keyword,
                                             description, tags, favicon_id, created, modified,
                                             guid, deleted, localVersion, syncVersion)
             VALUES (:_id, :title, :url, :type, :parent, :position, :keyword, :description, :tags,
                     :favicon_id, :created, :modified, :guid, :deleted, :localVersion, :syncVersion)"
        )?;
        stmt.execute_named(rusqlite::named_params! {
            ":_id": self._id,
            ":title": self.title,
            ":url": self.url,
            ":type": self.r#type,
            ":parent": self.parent,
            ":position": self.position,
            ":keyword": self.keyword,
            ":description": self.description,
            ":tags": self.tags,
            ":favicon_id": self.favicon_id,
            ":created": self.created,
            ":modified": self.modified,
            ":guid": self.guid,
            ":deleted": self.deleted,
            ":localVersion": self.local_version,
            ":syncVersion": self.sync_version,
        })?;
        Ok(())
    }
}

static ID_COUNTER: AtomicUsize = AtomicUsize::new(0);

// Helps debugging to use these instead of actually random ones.
fn next_guid() -> Guid {
    let c = ID_COUNTER.fetch_add(1, Ordering::SeqCst);
    let v = format!("test{}_______", c);
    let s = &v[..12];
    Guid::from(s)
}

impl Default for FennecBookmark {
    fn default() -> Self {
        Self {
            _id: 0,
            title: None,
            url: None,
            r#type: &FennecBookmarkType::Bookmark,
            parent: 0,
            position: 0,
            keyword: None,
            description: None,
            tags: None,
            favicon_id: None,
            created: Some(Timestamp::now()),
            modified: Some(Timestamp::now()),
            guid: next_guid(),
            deleted: false,
            local_version: 1,
            sync_version: 0,
        }
    }
}

fn insert_bookmarks(conn: &Connection, bookmarks: &[FennecBookmark]) -> Result<()> {
    for b in bookmarks {
        b.insert_into_db(conn)?;
    }
    Ok(())
}

#[test]
fn test_import_unsupported_db_version() -> Result<()> {
    let tmpdir = tempdir().unwrap();
    let fennec_path = tmpdir.path().join("browser.db");
    let fennec_db = empty_fennec_db(&fennec_path)?;
    fennec_db.execute("PRAGMA user_version=99", NO_PARAMS)?;
    let places_api = PlacesApi::new(tmpdir.path().join("places.sqlite"))?;
    match places::import::import_fennec_bookmarks(&places_api, fennec_path)
        .unwrap_err()
        .kind()
    {
        ErrorKind::UnsupportedDatabaseVersion(_) => {}
        _ => unreachable!("Should fail with UnsupportedDatabaseVersion!"),
    }
    Ok(())
}

fn get_fennec_roots() -> [FennecBookmark; 7] {
    [
        // Roots.
        FennecBookmark {
            _id: 0,
            parent: 0, // The root node is its own parent.
            guid: Guid::from("places"),
            r#type: &FennecBookmarkType::Folder,
            ..Default::default()
        },
        FennecBookmark {
            _id: -3,
            parent: 0,
            position: 5,
            guid: Guid::from("pinned"),
            title: Some("Pinned".to_owned()),
            r#type: &FennecBookmarkType::Folder,
            ..Default::default()
        },
        FennecBookmark {
            _id: 1,
            parent: 0,
            guid: Guid::from("mobile"),
            title: Some("Mobile Bookmarks".to_owned()),
            r#type: &FennecBookmarkType::Folder,
            ..Default::default()
        },
        FennecBookmark {
            _id: 2,
            parent: 0,
            guid: Guid::from("toolbar"),
            title: Some("Bookmarks Toolbar".to_owned()),
            r#type: &FennecBookmarkType::Folder,
            ..Default::default()
        },
        FennecBookmark {
            _id: 3,
            parent: 0,
            guid: Guid::from("menu"),
            title: Some("Bookmarks Menu".to_owned()),
            r#type: &FennecBookmarkType::Folder,
            ..Default::default()
        },
        FennecBookmark {
            _id: 4,
            parent: 0,
            guid: Guid::from("tags"),
            title: Some("Tags".to_owned()),
            r#type: &FennecBookmarkType::Folder,
            ..Default::default()
        },
        FennecBookmark {
            _id: 5,
            parent: 0,
            guid: Guid::from("unfiled"),
            title: Some("Other Bookmarks".to_owned()),
            r#type: &FennecBookmarkType::Folder,
            ..Default::default()
        },
    ]
}

fn bookmark_exists(places_api: &PlacesApi, url_str: &str) -> Result<bool> {
    use places::api::places_api::ConnectionType;
    use url::Url;

    let url = Url::parse(url_str)?;
    let conn = places_api.open_connection(ConnectionType::ReadOnly)?;
    Ok(conn.query_row_and_then(
        "SELECT EXISTS(
            SELECT 1 FROM main.moz_bookmarks b
            LEFT JOIN main.moz_places h ON h.id = b.fk
            WHERE h.url_hash = hash(:url) AND h.url = :url
        )",
        &[&url.as_str()],
        |r| r.get(0),
    )?)
}

#[test]
fn test_import() -> Result<()> {
    let _ = env_logger::try_init();

    let tmpdir = tempdir().unwrap();
    let fennec_path = tmpdir.path().join("browser.db");
    let fennec_path_pinned = fennec_path.clone();
    let fennec_db = empty_fennec_db(&fennec_path)?;

    let bookmarks = [
        FennecBookmark {
            _id: 6,
            parent: 1,
            title: Some("Firefox: About your browser".to_owned()),
            url: Some("about:firefox".to_owned()),
            position: 1,
            ..Default::default()
        },
        FennecBookmark {
            _id: 7,
            parent: 1,
            title: Some("Folder one".to_owned()),
            r#type: &FennecBookmarkType::Folder,
            ..Default::default()
        },
        FennecBookmark {
            _id: 8,
            parent: 7,
            title: Some("Foo".to_owned()),
            url: Some("https://bar.foo".to_owned()),
            position: -9_223_372_036_854_775_808, // Haaaaaa.
            favicon_id: Some(-2),                 // Hoooo.
            ..Default::default()
        },
        FennecBookmark {
            _id: 9,
            parent: 7,
            position: 0,
            r#type: &FennecBookmarkType::Separator,
            ..Default::default()
        },
        FennecBookmark {
            _id: 10,
            parent: 7,
            title: Some("Not a valid URL yo.".to_owned()),
            url: Some("foo bar unlimited edition".to_owned()),
            ..Default::default()
        },
        FennecBookmark {
            _id: 11,
            parent: -3,
            position: -1,
            title: Some("Pinned Bookmark".to_owned()),
            url: Some("https://foo.bar".to_owned()),
            ..Default::default()
        },
        FennecBookmark {
            _id: 12,
            parent: 7,
            title: Some("Non-punycode".to_owned()),
            url: Some("http://\u{1F496}.com/\u{1F496}".to_owned()),
            ..Default::default()
        },
        FennecBookmark {
            _id: 13,
            parent: 7,
            title: Some("Already punycode".to_owned()),
            url: Some("http://xn--r28h.com/%F0%9F%98%8D".to_owned()),
            ..Default::default()
        },
        FennecBookmark {
            _id: 14,
            parent: 7,
            position: 0,
            title: Some("Deleted Bookmark".to_owned()),
            url: Some("https://foo.bar/deleted".to_owned()),
            deleted: true,
            ..Default::default()
        },
    ];
    insert_bookmarks(&fennec_db, &get_fennec_roots())?;
    insert_bookmarks(&fennec_db, &bookmarks)?;

    // manually add other records with invalid data.
    // Note we always specify a valid "type" column as there is a CHECK
    // constraint in that in our staging table.
    // A parent with an id of -99.
    fennec_db
        .prepare(&format!(
            "
            INSERT INTO bookmarks(
                _id, title, url, type,
                parent, position, keyword, description, tags,
                favicon_id, created, modified,
                guid, deleted, localVersion, syncVersion
            ) VALUES (
                -99, 'test title', NULL, {},
                5, -1, NULL, NULL, NULL,
                -1, -1, -1,
                'invalid-guid', 0, -1, -1
            )",
            FennecBookmarkType::Folder as u8
        ))?
        .execute(NO_PARAMS)?;
    // An item with the parent as -99 and an invalid guid - both of these
    // invalid values will be fixed up and the item will be imported.
    fennec_db
        .prepare(&format!(
            "
            INSERT INTO bookmarks(
                _id, title, url, type,
                parent, position, keyword, description, tags,
                favicon_id, created, modified,
                guid, deleted, localVersion, syncVersion
            ) VALUES (
                999, 'test title 2', 'http://example.com/invalid_values', {},
                -99, 18446744073709551615, NULL, NULL, NULL,
                -1, -1, -1,
                'invalid-guid-2', 0, -1, -1
            )",
            FennecBookmarkType::Bookmark as u8
        ))?
        .execute(NO_PARAMS)?;

    let places_api = PlacesApi::new(tmpdir.path().join("places.sqlite"))?;

    let metrics = places::import::import_fennec_bookmarks(&places_api, fennec_path)?;
    let expected_metrics = BookmarksMigrationResult {
        num_succeeded: 13,
        total_duration: 4,
        num_failed: 1, // only failure is our bookmark with an invalid url.
        num_total: 14,
    };
    assert_eq!(metrics.num_succeeded, expected_metrics.num_succeeded);
    assert_eq!(metrics.num_failed, expected_metrics.num_failed);
    assert_eq!(metrics.num_total, expected_metrics.num_total);
    assert!(metrics.total_duration > 0);

    let pinned = places::import::import_fennec_pinned_sites(&places_api, fennec_path_pinned)?;
    assert_eq!(pinned.len(), 1);
    assert_eq!(pinned[0].title, Some("Pinned Bookmark".to_owned()));

    assert!(bookmark_exists(&places_api, &"about:firefox")?);
    assert!(bookmark_exists(&places_api, &"https://bar.foo")?);
    assert!(bookmark_exists(&places_api, &"http://💖.com/💖")?);
    assert!(bookmark_exists(&places_api, &"http://😍.com/😍")?);
    // Uncomment the following to debug with cargo test -- --nocapture.
    // println!(
    //     "Places DB Path: {}",
    //     tmpdir.path().join("places.sqlite").to_str().unwrap()
    // );
    // ::std::process::exit(0);

    Ok(())
}

#[test]
fn test_timestamp_sanitization() -> Result<()> {
    use places::api::places_api::ConnectionType;
    use places::import::common::NOW;
    use places::storage::bookmarks::public_node::fetch_bookmark;
    use std::time::{Duration, SystemTime};

    fn get_actual_timestamps(
        created: Timestamp,
        modified: Timestamp,
    ) -> Result<(Timestamp, Timestamp)> {
        let tmpdir = tempdir().unwrap();
        let fennec_path = tmpdir.path().join("browser.db");
        let fennec_db = empty_fennec_db(&fennec_path)?;

        let bookmarks = [FennecBookmark {
            _id: 6,
            guid: "bookmarkAAAA".into(),
            created: Some(created),
            modified: Some(modified),
            parent: 5,
            url: Some("http://example.com".to_owned()),
            ..Default::default()
        }];
        insert_bookmarks(&fennec_db, &get_fennec_roots())?;
        insert_bookmarks(&fennec_db, &bookmarks)?;

        let places_api = PlacesApi::new(tmpdir.path().join("places.sqlite"))?;
        places::import::import_fennec_bookmarks(&places_api, fennec_path)?;

        let reader = places_api.open_connection(ConnectionType::ReadOnly)?;
        let b = fetch_bookmark(&reader, &Guid::from("bookmarkAAAA"), true)?.unwrap();
        // regardless of what our caller asserts, modified must never be earlier than created.
        assert!(b.last_modified >= b.date_added);
        Ok((b.date_added, b.last_modified))
    }

    let now = *NOW;
    let stnow: SystemTime = now.into();
    let earlier: Timestamp = (stnow - Duration::new(10, 0)).into();
    let later: Timestamp = (stnow + Duration::new(10000, 0)).into();
    println!("Timestamp tests have now as {:?}", now);

    // sane timestamps, times equal -> as specified
    assert_eq!(get_actual_timestamps(now, now)?, (now, now));
    assert_eq!(get_actual_timestamps(earlier, earlier)?, (earlier, earlier));
    // sane timestamps, modified later than created -> as specified
    assert_eq!(get_actual_timestamps(earlier, now)?, (earlier, now));

    // sane timestamps, modified earlier than created -> both set to created.
    assert_eq!(get_actual_timestamps(now, earlier)?, (now, now));

    // NOTE: The results of testing not-sane is somewhat arbitrary - there are
    // a number of results which would be fine - so long as the 'created can't
    // be after modified' invaliant holds true (which is checked in
    // get_actual_timestamps())

    // created in the past and sane, modified not sane (too early) -> created as specified, modified = now
    // (easily argued that modified -> created is better, but that's tricky in the sql)
    assert_eq!(
        get_actual_timestamps(earlier, Timestamp(0))?,
        (earlier, now)
    );

    // created in the past and sane, modified not sane (too late) -> created as specified, modified = now
    assert_eq!(get_actual_timestamps(earlier, later)?, (earlier, now));

    // created not sane (too early), modified sane -> both set to now
    // (easily argued that both set to the earlier `modified` would be better,
    // but that's tricky in the sql)
    assert_eq!(get_actual_timestamps(Timestamp(0), earlier)?, (now, now));

    // created not sane (too late), modified sane -> both set to now
    // (easily argued that both set to the earlier `modified` would be better,
    // but that's tricky in the sql)
    assert_eq!(get_actual_timestamps(later, earlier)?, (now, now));

    // both too early -> both set to now
    assert_eq!(
        get_actual_timestamps(Timestamp(0), Timestamp(0))?,
        (now, now)
    );
    // both too late, both -> now
    assert_eq!(get_actual_timestamps(later, later)?, (now, now));
    Ok(())
}

// Test that timestamps of records with tags have early but sane dates.
#[test]
fn test_timestamp_sanitization_tags() -> Result<()> {
    use places::api::places_api::ConnectionType;
    use places::import::common::NOW;
    use places::storage::bookmarks::public_node::fetch_bookmark;
    use std::time::{Duration, SystemTime};

    fn get_actual_timestamp(created: Timestamp, modified: Timestamp) -> Result<Timestamp> {
        let tmpdir = tempdir().unwrap();
        let fennec_path = tmpdir.path().join("browser.db");
        let fennec_db = empty_fennec_db(&fennec_path)?;

        let bookmarks = [FennecBookmark {
            _id: 6,
            guid: "bookmarkAAAA".into(),
            created: Some(created),
            modified: Some(modified),
            parent: 5,
            url: Some("http://example.com".to_owned()),
            tags: Some("foo".to_owned()),
            ..Default::default()
        }];
        insert_bookmarks(&fennec_db, &get_fennec_roots())?;
        insert_bookmarks(&fennec_db, &bookmarks)?;

        let places_api = PlacesApi::new(tmpdir.path().join("places.sqlite"))?;
        places::import::import_fennec_bookmarks(&places_api, fennec_path)?;

        let reader = places_api.open_connection(ConnectionType::ReadOnly)?;
        let b = fetch_bookmark(&reader, &Guid::from("bookmarkAAAA"), true)?.unwrap();
        // for items with tags, created and modified are always identical.
        assert_eq!(b.date_added, b.last_modified);
        Ok(b.date_added)
    }

    let now = *NOW;
    let stnow: SystemTime = now.into();
    let earlier: Timestamp = (stnow - Duration::new(10, 0)).into();
    let later: Timestamp = (stnow + Duration::new(10000, 0)).into();
    println!("Timestamp (tag) tests have now as {:?}", now);

    // sane timestamps, times equal -> as specified
    assert_eq!(get_actual_timestamp(now, now)?, now);
    assert_eq!(get_actual_timestamp(earlier, earlier)?, earlier);
    // sane timestamps, modified later than created -> both to created
    assert_eq!(get_actual_timestamp(earlier, now)?, earlier);

    // sane timestamps, modified earlier than created -> both set to modified.
    assert_eq!(get_actual_timestamp(now, earlier)?, earlier);

    // created in the past and sane, modified not sane (too early) -> created
    assert_eq!(get_actual_timestamp(earlier, Timestamp(0))?, earlier);

    // created in the past and sane, modified not sane (too late) -> created
    assert_eq!(get_actual_timestamp(earlier, later)?, earlier);

    // created not sane (too early), modified sane -> both set to modified
    assert_eq!(get_actual_timestamp(Timestamp(0), earlier)?, earlier);

    // created not sane (too late), modified sane -> modified
    assert_eq!(get_actual_timestamp(later, earlier)?, earlier);

    // both too early, both -> now
    assert_eq!(get_actual_timestamp(Timestamp(0), Timestamp(0))?, now);
    // both too late, both -> now
    assert_eq!(get_actual_timestamp(later, later)?, now);
    Ok(())
}

#[test]
fn test_positions() -> Result<()> {
    use places::api::places_api::ConnectionType;
    use places::storage::bookmarks::public_node::fetch_bookmark;

    let tmpdir = tempdir().unwrap();
    let fennec_path = tmpdir.path().join("browser.db");
    let fennec_db = empty_fennec_db(&fennec_path)?;
    let bm1 = next_guid();
    let bm2 = next_guid();
    let bm3 = next_guid();

    let bookmarks = [
        FennecBookmark {
            _id: 6,
            guid: bm1.clone(),
            position: 99,
            parent: 5,
            title: Some("Firefox: About your browser".to_owned()),
            url: Some("about:firefox".to_owned()),
            ..Default::default()
        },
        FennecBookmark {
            _id: 7,
            guid: bm2.clone(),
            position: -99,
            parent: 5,
            title: Some("Foo".to_owned()),
            url: Some("https://bar.foo".to_owned()),
            ..Default::default()
        },
        FennecBookmark {
            _id: 8,
            guid: bm3.clone(),
            parent: 5,
            position: 0,
            r#type: &FennecBookmarkType::Separator,
            ..Default::default()
        },
    ];
    insert_bookmarks(&fennec_db, &get_fennec_roots())?;
    insert_bookmarks(&fennec_db, &bookmarks)?;

    let places_api = PlacesApi::new(tmpdir.path().join("places.sqlite"))?;
    places::import::import_fennec_bookmarks(&places_api, fennec_path)?;

    let unfiled = fetch_bookmark(
        &places_api.open_connection(ConnectionType::ReadOnly)?,
        &Guid::from("unfiled_____"),
        true,
    )?
    .expect("it exists");
    let children = unfiled.child_nodes.expect("have children");
    assert_eq!(children.len(), 3);
    // They should be ordered by the position and the actual positions updated.
    assert_eq!(children[0].guid, bm2);
    assert_eq!(children[0].position, 0);
    assert_eq!(children[1].guid, bm3);
    assert_eq!(children[1].position, 1);
    assert_eq!(children[2].guid, bm1);
    assert_eq!(children[2].position, 2);
    Ok(())
}

#[test]
fn test_null_parent() -> Result<()> {
    use places::api::places_api::ConnectionType;
    use places::storage::bookmarks::public_node::fetch_bookmark;

    let tmpdir = tempdir().unwrap();
    let fennec_path = tmpdir.path().join("browser.db");
    let fennec_db = empty_fennec_db(&fennec_path)?;

    insert_bookmarks(&fennec_db, &get_fennec_roots())?;

    // manually add a bookmark with a null parent.
    fennec_db
        .prepare(&format!(
            "
            INSERT INTO bookmarks(
                _id, title, url, type,
                parent, position, keyword, description, tags,
                favicon_id, created, modified,
                guid, deleted, localVersion, syncVersion
            ) VALUES (
                10, 'test title', NULL, {},
                NULL, -1, NULL, NULL, NULL,
                -1, -1, -1,
                'folderAAAAAA', 0, -1, -1
            )",
            FennecBookmarkType::Folder as u8
        ))?
        .execute(NO_PARAMS)?;

    let places_api = PlacesApi::new(tmpdir.path().join("places.sqlite"))?;
    places::import::import_fennec_bookmarks(&places_api, fennec_path)?;

    // should have ended up in unfiled.
    let unfiled = fetch_bookmark(
        &places_api.open_connection(ConnectionType::ReadOnly)?,
        &Guid::from("unfiled_____"),
        true,
    )?
    .expect("it exists");
    let children = unfiled.child_nodes.expect("have children");
    assert_eq!(children.len(), 1);
    assert_eq!(children[0].guid, "folderAAAAAA");
    Ok(())
}

#[test]
fn test_invalid_utf8() -> Result<()> {
    use places::api::places_api::ConnectionType;
    use places::storage::bookmarks::public_node::fetch_bookmark;
    use url::Url;

    let tmpdir = tempdir().unwrap();
    let fennec_path = tmpdir.path().join("browser.db");
    let fennec_db = empty_fennec_db(&fennec_path)?;

    let _ = env_logger::try_init();

    insert_bookmarks(&fennec_db, &get_fennec_roots())?;

    // use sqlites blob literal syntax to create "invalid char ->???<" where '???' are 3 invalid utf8 bytes.
    //                i n v a l i d   c h a r   - > ? ? ? <
    let bad = "CAST(X'696e76616c69642063686172202d3eF090803c' AS TEXT)";
    // this is what we expect it to end up as (note the replacement char)
    let fixed = "invalid char ->�<".to_string();

    // manually add a bookmark with a null parent.
    fennec_db
        .prepare(&format!(
            "
            INSERT INTO bookmarks(
                _id, title, url, type,
                parent, position, keyword, description,
                tags,
                favicon_id, created, modified,
                guid, deleted, localVersion, syncVersion
            ) VALUES (
                10, {bad}, 'http://example.com/' || {bad}, {bm_type},
                NULL, -1, {bad}, {bad},
                -- We don't migrate tags, so it doesn't matter if they are in
                -- the correct JSON format - we just want to ensure bad utf-8
                -- there doesn't kill the migration.
                {bad},
                -1, -1, -1,
                {bad}, 0, -1, -1
            )",
            bm_type = FennecBookmarkType::Bookmark as u8,
            bad = bad,
        ))?
        .execute(NO_PARAMS)?;

    let places_api = PlacesApi::new(tmpdir.path().join("places.sqlite"))?;
    places::import::import_fennec_bookmarks(&places_api, fennec_path)?;
    let conn = places_api.open_connection(ConnectionType::ReadOnly)?;

    // should have ended up in unfiled.
    let unfiled = fetch_bookmark(&conn, &Guid::from("unfiled_____"), true)?.expect("it exists");

    let url = Url::parse(&format!("http://example.com/{}", fixed))?;
    assert!(bookmark_exists(&places_api, url.as_str())?);

    let children = unfiled.child_nodes.expect("have children");
    assert_eq!(children.len(), 1);
    assert_eq!(children[0].title, Some(fixed));
    // We can't know exactly what the fixed guid is, but it must be valid.
    assert!(children[0].guid.is_valid_for_places());
    // Can't check keyword or tags because we drop them except for sync users
    // (and for them, we've dropped them until their first sync)
    Ok(())
}

#[test]
fn test_empty_db() -> Result<()> {
    // Test we don't break if there's an empty DB (ie, not even the roots)
    let tmpdir = tempdir().unwrap();
    let fennec_path = tmpdir.path().join("browser.db");
    empty_fennec_db(&fennec_path)?;

    let places_api = PlacesApi::new(tmpdir.path().join("places.sqlite"))?;
    let metrics = places::import::import_fennec_bookmarks(&places_api, fennec_path)?;

    // There were 0 Fennec bookmarks imported...
    assert_eq!(metrics.num_total, 0);
    // But we report a succeeded count of 5 because we still created the roots.
    // It's slightly odd, but it's OK for this edge case.
    assert_eq!(metrics.num_succeeded, 5);
    assert_eq!(metrics.num_failed, 0);
    assert!(metrics.total_duration > 0);
    Ok(())
}

enum TimestampTestType {
    LocalNewer,
    RemoteNewer,
}

fn do_test_sync_after_migrate(test_type: TimestampTestType) -> Result<()> {
    use places::api::places_api::ConnectionType;
    use places::bookmark_sync::store::BookmarksStore;
    use places::storage::bookmarks::bookmarks_get_url_for_keyword;
    use places::storage::tags;
    use serde_json::json;
    use std::collections::HashSet;
    use std::time::{Duration, SystemTime, UNIX_EPOCH};
    use sync15::{telemetry, IncomingChangeset, Payload, ServerTimestamp, Store};
    use url::Url;

    let _ = env_logger::try_init();

    let tmpdir = tempdir().unwrap();
    let fennec_path = tmpdir.path().join("browser.db");
    let fennec_db = empty_fennec_db(&fennec_path)?;

    let now = SystemTime::now();
    // We arrange for the "current time" on the server to be now, and modified
    // timestamp of our test item on the server to be 10 seconds ago.
    let item_server_timestamp: ServerTimestamp = ServerTimestamp::from_float_seconds(
        now.duration_since(UNIX_EPOCH).unwrap_or_default().as_secs() as f64 - 10.0,
    );
    let server_timestamp: ServerTimestamp = ServerTimestamp::from_float_seconds(
        now.duration_since(UNIX_EPOCH).unwrap_or_default().as_secs() as f64,
    );
    // The locally modified timestamp is either now or 20 seconds ago
    let timestamp_local: Timestamp = match test_type {
        TimestampTestType::LocalNewer => now.into(),
        TimestampTestType::RemoteNewer => (now - Duration::new(20, 0)).into(),
    };

    let bookmarks = [
        // This bookmark will have tags on the server.
        FennecBookmark {
            _id: 6,
            guid: "bookmarkAAAA".into(),
            created: Some(Timestamp::EARLIEST),
            modified: Some(timestamp_local),
            position: 0,
            parent: 5,
            // It doesn't matter what the tag is, just that *something* exists,
            // because our SQL will force the modified date to the create date
            // if it does.
            tags: Some("whatever".to_owned()),
            title: Some("A".to_owned()),
            url: Some("http://example.com/a".to_owned()),
            ..Default::default()
        },
        // This bookmark will have a keyword on the server.
        FennecBookmark {
            _id: 7,
            guid: "bookmarkBBBB".into(),
            created: Some(Timestamp::EARLIEST),
            modified: Some(timestamp_local),
            position: 1,
            parent: 5,
            // As above, it doesn't matter what the keyword is, just that it exists
            keyword: Some("whatever".to_owned()),
            title: Some("B".to_owned()),
            url: Some("http://example.com/b/%s".to_owned()),
            ..Default::default()
        },
    ];
    insert_bookmarks(&fennec_db, &get_fennec_roots())?;
    insert_bookmarks(&fennec_db, &bookmarks)?;

    let places_api = PlacesApi::new(tmpdir.path().join("places.sqlite"))?;
    let metrics = places::import::import_fennec_bookmarks(&places_api, fennec_path)?;
    assert_eq!(metrics.num_failed, 0);

    let writer = places_api.open_connection(ConnectionType::ReadWrite)?;
    let syncer = places_api.open_sync_connection()?;

    // Should be no bookmark with keyword 'a' yet.
    assert_eq!(bookmarks_get_url_for_keyword(&writer, "a")?, None);
    // And no URL with our test tag yet.
    assert_eq!(tags::get_urls_with_tag(&writer, "test-tag")?, []);

    // Now setup incoming records from the server with some of the data we
    // missed.
    let records = vec![
        json!({
            "id": "unfiled",
            "type": "folder",
            "parentid": "places",
            "parentName": "root",
            "dateAdded": Timestamp::EARLIEST,
            "title": "unfiled",
            "children": ["bookmarkAAAA", "bookmarkBBBB"],
        }),
        json!({
            "id": "bookmarkAAAA",
            "type": "bookmark",
            "parentid": "unfiled",
            "parentName": "unfiled",
            "dateAdded": Timestamp::EARLIEST,
            "title": "A",
            "bmkUri": "http://example.com/a",
            "tags": ["test-tag"],
        }),
        json!({
            "id": "bookmarkBBBB",
            "type": "bookmark",
            "parentid": "unfiled",
            "parentName": "unfiled",
            "dateAdded": Timestamp::EARLIEST,
            "title": "B",
            "bmkUri": "http://example.com/b/%s",
            "keyword": "b",
        }),
    ];

    let interrupt_scope = syncer.begin_interrupt_scope();
    let store = BookmarksStore::new(&syncer, &interrupt_scope);

    let mut incoming =
        IncomingChangeset::new(store.collection_name().to_string(), server_timestamp);
    for record in records {
        let payload = Payload::from_json(record).unwrap();
        incoming.changes.push((payload, item_server_timestamp));
    }

    let outgoing = store
        .apply_incoming(vec![incoming], &mut telemetry::Engine::new("bookmarks"))
        .expect("Should apply incoming records");
    let outgoing_ids: HashSet<_> = outgoing
        .changes
        .iter()
        .map(|p| p.id.clone().into_string())
        .collect();

    // Note that most of the roots *are* in outgoing - dogear always uploads
    // roots in this case - all the gory details are explained in
    // https://github.com/mozilla/application-services/pull/2496#discussion_r369327069
    // If dogear reverts this behaviour (which it arguably should), this may
    // change. tl;dr - we can't simply assert outgoing is empty here!

    // Another subtlety:
    // * If bookmarkAAAA was in outgoing, we'd actually lose the tag (we'd upload
    //   the record without one) - so it's vital that's not in outgoing.
    // * If bookmarkBBBB was in outgoing, we'd still keep the keyword (we'd still
    //   upload the record with it in place) - so this is, basically, an
    //   optimization. This is explained in detail via
    //   https://github.com/mozilla/application-services/pull/2496#discussion_r369328161
    //   but it's basically an implementation detail.
    assert!(!outgoing_ids.contains("bookmarkAAAA"), "{:?}", outgoing_ids);
    assert!(!outgoing_ids.contains("bookmarkBBBB"), "{:?}", outgoing_ids);

    // We should always end up with the tag.
    assert_eq!(
        tags::get_urls_with_tag(&writer, "test-tag")?,
        [Url::parse("http://example.com/a")?]
    );
    // We should always end up with the keyword.
    assert_eq!(
        bookmarks_get_url_for_keyword(&writer, "b")?,
        Some(Url::parse("http://example.com/b/%s")?)
    );

    Ok(())
}

#[test]
fn test_sync_after_migrate_local_newer() -> Result<()> {
    do_test_sync_after_migrate(TimestampTestType::LocalNewer)
}

#[test]
fn test_sync_after_migrate_remote_newer() -> Result<()> {
    do_test_sync_after_migrate(TimestampTestType::RemoteNewer)
}
