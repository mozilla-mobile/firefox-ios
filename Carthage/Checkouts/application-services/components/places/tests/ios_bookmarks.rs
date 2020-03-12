/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use dogear::Guid;
use places::{
    api::places_api::{ConnectionType, PlacesApi},
    import::ios_bookmarks::IosBookmarkType,
    storage::bookmarks,
    Result, Timestamp,
};
use rusqlite::Connection;
use sql_support::ConnExt;
use std::collections::HashMap;
use std::path::Path;
use std::sync::atomic::{AtomicUsize, Ordering};
use sync_guid::Guid as SyncGuid;
use tempfile::tempdir;

fn empty_ios_db(path: &Path) -> Result<Connection> {
    let conn = Connection::open(path)?;
    conn.execute_batch(include_str!("./ios_schema.sql"))?;
    Ok(conn)
}

#[derive(Clone, Debug)]
struct IosNode {
    guid: dogear::Guid,
    ty: IosBookmarkType,

    parentid: dogear::Guid,

    // pos: Option<i64>,
    title: Option<String>,

    bmk_uri: Option<String>,
    tags: Option<Vec<String>>,
    keyword: Option<String>,

    modified: Option<Timestamp>,
    date_added: Option<Timestamp>,
    children: Option<Vec<Guid>>,

    // My iOS bookmarksLocalStructure has `toolbar_____` and `menu________` at
    // the same `pos` under `root________`...
    hacky_force_structure_pos: Option<i64>,
}

static ID_COUNTER: AtomicUsize = AtomicUsize::new(0);

// Helps debugging to use these instead of actually random ones.
fn next_guid() -> Guid {
    let c = ID_COUNTER.fetch_add(1, Ordering::SeqCst);
    let v = format!("test{}_______", c);
    let s = &v[..12];
    Guid::from(s)
}

impl Default for IosNode {
    fn default() -> Self {
        Self {
            guid: next_guid(),

            ty: IosBookmarkType::Bookmark,
            parentid: dogear::UNFILED_GUID,

            // pos: None,
            title: None,

            bmk_uri: None,
            tags: None,
            keyword: None,

            hacky_force_structure_pos: None,
            modified: Some(Timestamp::now()),
            date_added: Some(Timestamp::now()),
            children: None,
        }
    }
}

#[derive(Clone, Debug)]
pub struct IosTree {
    buffer: HashMap<Guid, IosNode>,
    local: HashMap<Guid, IosNode>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
enum IosTables {
    Buffer,
    Local,
}

impl IosTables {
    fn data_table(self) -> &'static str {
        match self {
            IosTables::Buffer => "bookmarksBuffer",
            IosTables::Local => "bookmarksLocal",
        }
    }
    fn structure_table(self) -> &'static str {
        match self {
            IosTables::Buffer => "bookmarksBufferStructure",
            IosTables::Local => "bookmarksLocalStructure",
        }
    }
    fn modified_col(self) -> &'static str {
        match self {
            IosTables::Buffer => "server_modified",
            IosTables::Local => "local_modified",
        }
    }
    fn opposite(self) -> IosTables {
        match self {
            IosTables::Buffer => IosTables::Local,
            IosTables::Local => IosTables::Buffer,
        }
    }
}

fn is_root(g: &Guid) -> bool {
    g.is_built_in_root() || g == dogear::ROOT_GUID
}

impl IosTree {
    fn new() -> Self {
        let mut res = Self {
            local: HashMap::default(),
            buffer: HashMap::default(),
        };
        let root = IosNode {
            guid: dogear::ROOT_GUID,
            parentid: dogear::ROOT_GUID,
            title: Some(String::new()),
            ty: IosBookmarkType::Folder,
            children: Some(vec![
                dogear::MENU_GUID,
                dogear::TOOLBAR_GUID,
                dogear::UNFILED_GUID,
                dogear::MOBILE_GUID,
            ]),
            ..IosNode::default()
        };
        let menu = IosNode {
            guid: dogear::MENU_GUID,
            parentid: dogear::ROOT_GUID,
            title: Some(String::new()),
            ty: IosBookmarkType::Folder,
            children: Some(vec![]),
            hacky_force_structure_pos: Some(0),
            ..IosNode::default()
        };
        let toolbar = IosNode {
            guid: dogear::TOOLBAR_GUID,
            parentid: dogear::ROOT_GUID,
            title: Some(String::new()),
            ty: IosBookmarkType::Folder,
            children: Some(vec![]),
            hacky_force_structure_pos: Some(0),
            ..IosNode::default()
        };
        let unfiled = IosNode {
            guid: dogear::UNFILED_GUID,
            parentid: dogear::ROOT_GUID,
            title: Some(String::new()),
            ty: IosBookmarkType::Folder,
            children: Some(vec![]),
            hacky_force_structure_pos: Some(1),
            ..IosNode::default()
        };

        let mobile = IosNode {
            guid: dogear::MOBILE_GUID,
            parentid: dogear::ROOT_GUID,
            title: Some(String::new()),
            ty: IosBookmarkType::Folder,
            children: Some(vec![]),
            hacky_force_structure_pos: Some(2),
            ..IosNode::default()
        };
        res.local.insert(dogear::ROOT_GUID, root);
        res.local.insert(dogear::MENU_GUID, menu.clone());
        res.local.insert(dogear::TOOLBAR_GUID, toolbar.clone());
        res.local.insert(dogear::UNFILED_GUID, unfiled.clone());
        res.local.insert(dogear::MOBILE_GUID, mobile.clone());
        // buffer does not have `root`, but does have these.
        res.buffer.insert(dogear::MENU_GUID, menu);
        res.buffer.insert(dogear::TOOLBAR_GUID, toolbar);
        res.buffer.insert(dogear::UNFILED_GUID, unfiled);
        res.buffer.insert(dogear::MOBILE_GUID, mobile);

        res
    }

    fn get_nodes(&self, t: IosTables) -> &HashMap<Guid, IosNode> {
        match t {
            IosTables::Buffer => &self.buffer,
            IosTables::Local => &self.local,
        }
    }

    fn populate(&self, conn: &Connection) -> Result<()> {
        let tx = conn.unchecked_transaction()?;
        self.do_populate(conn, IosTables::Buffer)?;
        self.do_populate(conn, IosTables::Local)?;
        tx.commit()?;
        Ok(())
    }

    fn do_populate(&self, conn: &Connection, dest: IosTables) -> Result<()> {
        let nodes = self.get_nodes(dest);
        let mut stmt = conn.prepare(&format!(
            "INSERT INTO {table}(
                guid,
                type,
                parentid,
                parentName,
                pos,
                title,
                bmkUri,
                tags,
                keyword,
                {modified_col},
                date_added
            ) VALUES (
                :guid,
                :type,
                :parentid,
                :parentName,
                :pos,
                :title,
                :bmkUri,
                :tags,
                :keyword,
                :modified,
                :date_added
            )",
            table = dest.data_table(),
            modified_col = dest.modified_col(),
        ))?;

        for node in nodes.values() {
            let parent = if let Some(n) = nodes.get(&node.parentid) {
                n
            } else {
                &self.get_nodes(dest.opposite())[&node.parentid]
            };
            stmt.execute_named(rusqlite::named_params! {
                ":guid": node.guid.as_str(),
                ":type": node.ty as u8,
                ":parentid": node.parentid.as_str(),
                ":parentName": parent.title,
                ":pos": if node.ty == IosBookmarkType::Separator {
                    Some(parent.children.as_ref().unwrap().iter().position(|id| id == node.guid).expect("separator is not child of parent") as i64)
                } else {
                    None
                },
                ":title": node.title,
                ":bmkUri": node.bmk_uri,
                ":tags": node.tags.as_ref().map(|t| serde_json::to_string(t).unwrap()),
                ":keyword": node.keyword,
                ":modified": node.modified,
                ":date_added": node.date_added,
            })?;
        }

        self.do_populate_structure(conn, dest)?;
        Ok(())
    }

    fn do_populate_structure(&self, conn: &Connection, dest: IosTables) -> Result<()> {
        let mut stmt = conn.prepare(&format!(
            "INSERT INTO {}(parent, child, idx) VALUES (:parent, :child, :idx)",
            dest.structure_table()
        ))?;
        let nodes = self.get_nodes(dest);
        for node in nodes.values() {
            if node.ty != IosBookmarkType::Folder {
                continue;
            }
            let kids = node.children.as_ref().unwrap();
            for (pos, kid_id) in kids.iter().enumerate() {
                let idx = nodes[kid_id]
                    .hacky_force_structure_pos
                    .unwrap_or(pos as i64);
                stmt.execute_named(rusqlite::named_params! {
                    ":parent": node.guid.as_str(),
                    ":child": kid_id.as_str(),
                    ":idx": idx,
                })?;
            }
        }
        Ok(())
    }

    fn insert_buffer(&mut self, n: IosNode) -> Guid {
        assert!(!is_root(&n.guid));
        assert_ne!(n.parentid, dogear::ROOT_GUID);
        assert_eq!(n.ty == IosBookmarkType::Folder, n.children.is_some());
        let guid = n.guid.clone();
        {
            let parent = self.buffer.get_mut(&n.parentid).expect("No such parent");
            assert_eq!(parent.ty, IosBookmarkType::Folder);
            parent.children.as_mut().unwrap().push(guid.clone());
            dbg!((&parent.guid, &parent.children));
        }
        self.buffer.insert(guid.clone(), n);
        guid
    }

    fn insert_local(&mut self, n: IosNode) -> Guid {
        assert!(!is_root(&n.guid));
        assert_eq!(n.parentid, dogear::MOBILE_GUID);
        assert_eq!(n.ty, IosBookmarkType::Bookmark);
        let guid = n.guid.clone();
        {
            let parent = self
                .local
                .get_mut(&dogear::MOBILE_GUID)
                .expect("No such parent");
            parent.children.as_mut().unwrap().push(guid.clone());
        }
        self.local.insert(guid.clone(), n);
        guid
    }
}

#[test]
fn test_import_empty() -> Result<()> {
    let tmpdir = tempdir().unwrap();
    let nodes = IosTree::new();
    let ios_path = tmpdir.path().join("browser.db");
    let ios_db = empty_ios_db(&ios_path)?;

    nodes.populate(&ios_db)?;
    let places_api = PlacesApi::new(tmpdir.path().join("places.sqlite"))?;
    places::import::import_ios_bookmarks(&places_api, ios_path)?;

    Ok(())
}

// XXX SyncGuid is a pain to work with, but apparently dogear::Guid can't turn
// into it because of our blanket into impl... ;_;
fn sync_guid(d: &dogear::Guid) -> SyncGuid {
    SyncGuid::from(d.as_str())
}

#[test]
fn test_import_basic() -> Result<()> {
    let tmpdir = tempdir().unwrap();
    let mut nodes = IosTree::new();
    let ios_path = tmpdir.path().join("browser.db");
    let ios_db = empty_ios_db(&ios_path)?;

    let folder_id = nodes.insert_buffer(IosNode {
        ty: IosBookmarkType::Folder,
        title: Some("asdf".into()),
        parentid: dogear::UNFILED_GUID,
        children: Some(vec![]),
        ..IosNode::default()
    });

    let bmk_id = nodes.insert_buffer(IosNode {
        bmk_uri: Some("https://www.example.com/123".into()),
        parentid: folder_id.clone(),
        ..IosNode::default()
    });

    let sep_id = nodes.insert_buffer(IosNode {
        parentid: dogear::UNFILED_GUID,
        ty: IosBookmarkType::Separator,
        ..IosNode::default()
    });

    nodes.populate(&ios_db)?;
    let places_api = PlacesApi::new(tmpdir.path().join("places.sqlite"))?;
    places::import::import_ios_bookmarks(&places_api, ios_path)?;

    let places_db = places_api.open_connection(ConnectionType::ReadOnly)?;

    let sep =
        bookmarks::public_node::fetch_bookmark(&places_db, &sync_guid(&sep_id), false)?.unwrap();
    assert_eq!(sep.node_type, places::BookmarkType::Separator);

    let bmk =
        bookmarks::public_node::fetch_bookmark(&places_db, &sync_guid(&bmk_id), false)?.unwrap();
    assert_eq!(bmk.node_type, places::BookmarkType::Bookmark);
    assert_eq!(
        bmk.url,
        Some(url::Url::parse("https://www.example.com/123").unwrap())
    );
    assert_eq!(bmk.parent_guid, Some(sync_guid(&folder_id)));

    let fld =
        bookmarks::public_node::fetch_bookmark(&places_db, &sync_guid(&folder_id), false)?.unwrap();
    assert_eq!(fld.node_type, places::BookmarkType::Folder);
    assert_eq!(fld.child_guids, Some(vec![sync_guid(&bmk_id)]));

    Ok(())
}

#[test]
fn test_import_with_local() -> Result<()> {
    let tmpdir = tempdir().unwrap();
    let mut nodes = IosTree::new();
    let ios_path = tmpdir.path().join("browser.db");
    let ios_db = empty_ios_db(&ios_path)?;

    let b0id = nodes.insert_local(IosNode {
        bmk_uri: Some("https://www.example.com/123".into()),
        parentid: dogear::MOBILE_GUID,
        ..IosNode::default()
    });

    let b1id = nodes.insert_local(IosNode {
        bmk_uri: Some("https://www.example.com/1 2 3".into()),
        parentid: dogear::MOBILE_GUID,
        ..IosNode::default()
    });

    let b2id = nodes.insert_local(IosNode {
        bmk_uri: Some("http://💖.com/💖".into()),
        parentid: dogear::MOBILE_GUID,
        ..IosNode::default()
    });

    let b3id = nodes.insert_local(IosNode {
        bmk_uri: Some("http://xn--r28h.com/%F0%9F%98%8D".into()),
        parentid: dogear::MOBILE_GUID,
        ..IosNode::default()
    });

    nodes.populate(&ios_db)?;
    let places_api = PlacesApi::new(tmpdir.path().join("places.sqlite"))?;
    places::import::import_ios_bookmarks(&places_api, ios_path)?;

    let places_db = places_api.open_connection(ConnectionType::ReadOnly)?;

    let bmk0 =
        bookmarks::public_node::fetch_bookmark(&places_db, &sync_guid(&b0id), false)?.unwrap();
    assert_eq!(bmk0.node_type, places::BookmarkType::Bookmark);
    assert_eq!(bmk0.parent_guid, Some(sync_guid(&dogear::MOBILE_GUID)));
    assert_eq!(
        bmk0.url,
        Some(url::Url::parse("https://www.example.com/123").unwrap())
    );

    let bmk1 =
        bookmarks::public_node::fetch_bookmark(&places_db, &sync_guid(&b1id), false)?.unwrap();
    assert_eq!(bmk1.node_type, places::BookmarkType::Bookmark);
    assert_eq!(bmk1.parent_guid, Some(sync_guid(&dogear::MOBILE_GUID)));
    assert_eq!(
        bmk1.url,
        Some(url::Url::parse("https://www.example.com/1%202%203").unwrap())
    );

    let bmk2 =
        bookmarks::public_node::fetch_bookmark(&places_db, &sync_guid(&b2id), false)?.unwrap();
    assert_eq!(bmk2.url, Some(url::Url::parse("http://💖.com/💖").unwrap()));

    let bmk3 =
        bookmarks::public_node::fetch_bookmark(&places_db, &sync_guid(&b3id), false)?.unwrap();
    assert_eq!(bmk3.url, Some(url::Url::parse("http://😍.com/😍").unwrap()));

    let mobile = bookmarks::public_node::fetch_bookmark(
        &places_db,
        &sync_guid(&dogear::MOBILE_GUID),
        false,
    )?
    .unwrap();

    assert_eq!(
        mobile.child_guids,
        Some(vec![
            sync_guid(&b0id),
            sync_guid(&b1id),
            sync_guid(&b2id),
            sync_guid(&b3id)
        ])
    );

    Ok(())
}
