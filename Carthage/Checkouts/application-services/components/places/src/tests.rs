/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use rusqlite::NO_PARAMS;
use serde_json::Value;

use crate::{
    db::PlacesDb,
    storage::bookmarks::{fetch_tree, insert_tree, BookmarkTreeNode, FetchDepth},
};
use sync_guid::Guid as SyncGuid;

use pretty_assertions::assert_eq;

pub fn insert_json_tree(conn: &PlacesDb, jtree: Value) {
    let tree: BookmarkTreeNode = serde_json::from_value(jtree).expect("should be valid");
    let folder_node = match tree {
        BookmarkTreeNode::Folder(folder_node) => folder_node,
        _ => panic!("must be a folder"),
    };
    insert_tree(conn, &folder_node).expect("should insert");
}

pub fn assert_json_tree(conn: &PlacesDb, folder: &SyncGuid, expected: Value) {
    assert_json_tree_with_depth(conn, folder, expected, &FetchDepth::Deepest)
}

pub fn assert_json_tree_with_depth(
    conn: &PlacesDb,
    folder: &SyncGuid,
    expected: Value,
    target_depth: &FetchDepth,
) {
    let (fetched, _, _) = fetch_tree(conn, folder, target_depth)
        .expect("error fetching tree")
        .unwrap();
    let deser_tree: BookmarkTreeNode = serde_json::from_value(expected).unwrap();
    assert_eq!(fetched, deser_tree);
    // and while checking the tree, check positions are correct.
    check_positions(&conn);
}

// check the positions for children in a folder are "correct" in that
// the first child has a value of zero, etc - ie, this will fail if there
// are holes or duplicates in the position values.
// Clever implementation stolen from desktop.
pub fn check_positions(conn: &PlacesDb) {
    // Use triangular numbers to detect skipped position, then
    // a subquery to select enough fields to help diagnose when it fails.
    let sql = "
        WITH bad_parents(pid) as (
            SELECT parent
            FROM moz_bookmarks
            GROUP BY parent
            HAVING (SUM(DISTINCT position + 1) - (count(*) * (count(*) + 1) / 2)) <> 0
        )
        SELECT parent, guid, title, position FROM moz_bookmarks
        WHERE parent in bad_parents
        ORDER BY parent, position
    ";

    let mut stmt = conn.prepare(sql).expect("sql is ok");
    let parents: Vec<_> = stmt
        .query_and_then(NO_PARAMS, |row| -> rusqlite::Result<_> {
            Ok((
                row.get::<_, i64>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, Option<String>>(2)?,
                row.get::<_, u32>(3)?,
            ))
        })
        .expect("should work")
        .map(Result::unwrap)
        .collect();

    assert_eq!(parents, Vec::new());
}
