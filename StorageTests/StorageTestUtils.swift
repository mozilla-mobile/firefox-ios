/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Note that this file is imported into SyncTests, too.

import Deferred
import Foundation
import Shared
@testable import Storage
import XCTest

extension BrowserDB {
    func assertQueryReturns(_ query: String, int: Int) {
        XCTAssertEqual(int, self.runQuery(query, args: nil, factory: IntFactory).value.successValue![0])
    }
}

extension BrowserDB {
    func moveLocalToMirrorForTesting() {
        // This is a risky process -- it's not the same logic that the real synchronizer uses
        // (because I haven't written it yet), so it might end up lying. We do what we can.
        let valueSQL = [
            "INSERT OR IGNORE INTO \(TableBookmarksMirror)",
            "(guid, type, bmkUri, title, parentid, parentName, feedUri, siteUri, pos,",
            " description, tags, keyword, folderName, queryId,",
            " is_overridden, server_modified, faviconID)",
            "SELECT guid, type, bmkUri, title, parentid, parentName,",
            "feedUri, siteUri, pos, description, tags, keyword, folderName, queryId,",
            "0 AS is_overridden, \(Date.now()) AS server_modified, faviconID",
            "FROM \(TableBookmarksLocal)",
        ].joined(separator: " ")

        // Copy its mirror structure.
        let structureSQL = "INSERT INTO \(TableBookmarksMirrorStructure) SELECT * FROM \(TableBookmarksLocalStructure)"

        // Throw away the old.
        let deleteLocalStructureSQL = "DELETE FROM \(TableBookmarksLocalStructure)"
        let deleteLocalSQL = "DELETE FROM \(TableBookmarksLocal)"

        self.run([
            valueSQL,
            structureSQL,
            deleteLocalStructureSQL,
            deleteLocalSQL,
        ]).succeeded()
    }

    func moveBufferToMirrorForTesting() {
        let valueSQL = [
            "INSERT OR IGNORE INTO \(TableBookmarksMirror)",
            "(guid, type, bmkUri, title, parentid, parentName, feedUri, siteUri, pos,",
            "description, tags, keyword, folderName, queryId, server_modified)",
            "SELECT",
            "guid, type, bmkUri, title, parentid, parentName, feedUri, siteUri, pos,",
            "description, tags, keyword, folderName, queryId, server_modified",
            "FROM \(TableBookmarksBuffer)",
        ].joined(separator: " ")

        let structureSQL = "INSERT INTO \(TableBookmarksMirrorStructure) SELECT * FROM \(TableBookmarksBufferStructure)"
        let deleteBufferStructureSQL = "DELETE FROM \(TableBookmarksBufferStructure)"
        let deleteBufferSQL = "DELETE FROM \(TableBookmarksBuffer)"

        self.run([
            valueSQL,
            structureSQL,
            deleteBufferStructureSQL,
            deleteBufferSQL,
        ]).succeeded()
    }
}

extension BrowserDB {
    func getGUIDs(_ sql: String) -> [GUID] {
        func guidFactory(_ row: SDRow) -> GUID {
            return row[0] as! GUID
        }

        guard let cursor = self.runQuery(sql, args: nil, factory: guidFactory).value.successValue else {
            XCTFail("Unable to get cursor.")
            return []
        }
        return cursor.asArray()
    }

    func getPositionsForChildrenOfParent(_ parent: GUID, fromTable table: String) -> [GUID: Int] {
        let args: Args = [parent]
        let factory: (SDRow) -> (GUID, Int) = {
            return ($0["child"] as! GUID, $0["idx"] as! Int)
        }
        let cursor = self.runQuery("SELECT child, idx FROM \(table) WHERE parent = ?", args: args, factory: factory).value.successValue!
        return cursor.reduce([:], { (dict, pair) in
            var dict = dict
            if let (k, v) = pair {
                dict[k] = v
            }
            return dict
        })
    }

    func isLocallyDeleted(_ guid: GUID) -> Bool? {
        let args: Args = [guid]
        let cursor = self.runQuery("SELECT is_deleted FROM \(TableBookmarksLocal) WHERE guid = ?", args: args, factory: { $0.getBoolean("is_deleted") }).value.successValue!
        return cursor[0]
    }

    func isOverridden(_ guid: GUID) -> Bool? {
        let args: Args = [guid]
        let cursor = self.runQuery("SELECT is_overridden FROM \(TableBookmarksMirror) WHERE guid = ?", args: args, factory: { $0.getBoolean("is_overridden") }).value.successValue!
        return cursor[0]
    }

    func getSyncStatusForGUID(_ guid: GUID) -> SyncStatus? {
        let args: Args = [guid]
        let cursor = self.runQuery("SELECT sync_status FROM \(TableBookmarksLocal) WHERE guid = ?", args: args, factory: { $0[0] as! Int }).value.successValue!
        if let raw = cursor[0] {
            return SyncStatus(rawValue: raw)
        }
        return nil
    }

    func getRecordByURL(_ url: String, fromTable table: String) -> BookmarkMirrorItem {
        let args: Args = [url]
        return self.runQuery("SELECT * FROM \(table) WHERE bmkUri = ?", args: args, factory: BookmarkFactory.mirrorItemFactory).value.successValue![0]!
    }

    func getRecordByGUID(_ guid: GUID, fromTable table: String) -> BookmarkMirrorItem {
        let args: Args = [guid]
        return self.runQuery("SELECT * FROM \(table) WHERE guid = ?", args: args, factory: BookmarkFactory.mirrorItemFactory).value.successValue![0]!
    }

    func getChildrenOfFolder(_ folder: GUID) -> [GUID] {
        let args: Args = [folder]
        let sql =
        "SELECT child FROM \(ViewBookmarksLocalStructureOnMirror) " +
        "WHERE parent = ? " +
        "ORDER BY idx ASC"
        return self.runQuery(sql, args: args, factory: { $0[0] as! GUID }).value.successValue!.asArray()
    }
}
